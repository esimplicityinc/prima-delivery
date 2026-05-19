#!/usr/bin/env python3
"""
Build a draw.io / diagrams.net XML file from the same nodes/arrows JSON shape
used by fireworks-tech-graph. Output is a `.drawio` file openable in
diagrams.net (web), draw.io desktop, or the VS Code drawio plugin.

Why a second renderer
---------------------
fireworks-tech-graph produces clean topology diagrams but its layout engine
struggles with dense feedback graphs (many backloop arrows on a single
spine - labels collide, lines overlap). draw.io has a mature routing engine
that handles this density well, including curved arrows, explicit waypoints,
and entry/exit ports.

Output is .drawio XML only (no SVG/PNG export). To render PNG, open the
file in draw.io and File -> Export As -> PNG, or install drawio-desktop CLI
and run `drawio -x -f png input.drawio`.

Usage:
  python3 build-drawio.py <input.json> <output.drawio>

Input JSON shape (compatible with the fireworks-tech-graph shape, with two
optional draw.io-specific extensions per node and edge):

  {
    "title": "Diagram title",
    "subtitle": "...",
    "viewBox": "0 0 1280 1280",   // page width/height (only the last two numbers used)
    "nodes": [
      {
        "id": "node1",
        "label": "Multi\\nline\\nlabel works",
        "kind": "process",         // process | decision | data | terminator
        "x": 100, "y": 100, "width": 200, "height": 80,
        "style_overrides": "..."   // optional: append/override drawio style
      }
    ],
    "arrows": [
      {
        "source": "node1",
        "target": "node2",
        "label": "edge label",
        "kind": "control",          // control | feedback | data
        "exit_port": "B",           // T | B | L | R (top/bottom/left/right) or None
        "entry_port": "T",
        "waypoints": [{"x": 200, "y": 400}],  // optional explicit routing
        "style_overrides": "..."
      }
    ],
    "containers": [
      {
        "id": "lane1",
        "label": "Layer label",
        "x": 40, "y": 80, "width": 1200, "height": 120,
        "style_overrides": "fillColor=#f8fafc;strokeColor=#cbd5e1;"
      }
    ],
    "legend": [
      { "label": "Build/data flow", "kind": "control" },
      { "label": "Auth/OIDC", "kind": "auth" }
    ],
    "legend_position": { "x": 40, "y": 920, "width": 1120 }
  }

Reference architecture posture: no hardcoded paths or project names. The
script reads paths from argv and the input JSON only.
"""

from __future__ import annotations

import json
import sys
import uuid
from html import escape
from pathlib import Path
from typing import Any

# Visual language: pick fills/strokes that look balanced together.
NODE_STYLES: dict[str, str] = {
    "process": (
        "rounded=1;whiteSpace=wrap;html=1;arcSize=15;"
        "fillColor=#e8eaf6;strokeColor=#3949ab;fontSize=14;fontStyle=1;"
        "shadow=0;"
    ),
    "decision": (
        "rhombus;whiteSpace=wrap;html=1;"
        "fillColor=#fff8e1;strokeColor=#f57f17;fontSize=14;fontStyle=1;"
    ),
    "data": (
        "rounded=1;whiteSpace=wrap;html=1;arcSize=15;"
        "fillColor=#e8f5e9;strokeColor=#2e7d32;fontSize=14;fontStyle=1;"
    ),
    "terminator": (
        "ellipse;whiteSpace=wrap;html=1;"
        "fillColor=#eceff1;strokeColor=#455a64;fontSize=14;"
    ),
}

# Edge styles by kind. Feedback uses a curved purple dashed line so backloops
# read as semantically different from forward control flow.
EDGE_STYLES: dict[str, str] = {
    "control": (
        "endArrow=classic;html=1;rounded=1;"
        "strokeColor=#1565c0;strokeWidth=2;fontSize=12;"
    ),
    "feedback": (
        "endArrow=classic;html=1;rounded=1;curved=1;dashed=1;"
        "strokeColor=#7b1fa2;strokeWidth=2;fontSize=11;fontStyle=2;"
    ),
    "data": (
        "endArrow=classic;html=1;rounded=1;dashed=1;"
        "strokeColor=#2e7d32;strokeWidth=1.5;fontSize=11;"
    ),
    "auth": (
        "endArrow=classic;html=1;rounded=1;dashed=1;"
        "strokeColor=#7c3aed;strokeWidth=1.5;fontSize=11;fontStyle=2;"
    ),
    "trigger": (
        "endArrow=classic;html=1;rounded=1;"
        "strokeColor=#ea580c;strokeWidth=2;fontSize=11;"
    ),
    "verify": (
        "endArrow=classic;html=1;rounded=1;"
        "strokeColor=#059669;strokeWidth=2;fontSize=11;"
    ),
    "user": (
        "endArrow=classic;html=1;rounded=1;"
        "strokeColor=#374151;strokeWidth=1.5;fontSize=11;"
    ),
}

CONTAINER_STYLE = (
    "rounded=1;whiteSpace=wrap;html=1;arcSize=6;dashed=1;dashPattern=4 4;"
    "fillColor=#f8fafc;strokeColor=#cbd5e1;fontColor=#475569;"
    "fontSize=12;fontStyle=1;align=left;verticalAlign=top;"
    "spacingLeft=16;spacingTop=10;"
)

LEGEND_KIND_COLORS: dict[str, str] = {
    "control": "#1565c0",
    "feedback": "#7b1fa2",
    "data": "#2e7d32",
    "auth": "#7c3aed",
    "trigger": "#ea580c",
    "verify": "#059669",
    "user": "#374151",
}

# Port shorthand to drawio (exitX, exitY) / (entryX, entryY) coordinates.
PORTS: dict[str, tuple[float, float]] = {
    "T": (0.5, 0.0),
    "B": (0.5, 1.0),
    "L": (0.0, 0.5),
    "R": (1.0, 0.5),
    "TL": (0.0, 0.0),
    "TR": (1.0, 0.0),
    "BL": (0.0, 1.0),
    "BR": (1.0, 1.0),
}

# Auto-stagger config for `lane` field. The closest lane sits LANE_BASE_OFFSET
# px outside the source/target node's edge; each additional lane adds
# LANE_SPACING px. Empirically tuned: 60+50 keeps labels (~150px wide each)
# from colliding while staying compact enough that 6+ nested arcs fit in a
# reasonable margin.
LANE_BASE_OFFSET = 60.0
LANE_SPACING = 50.0


def fail(msg: str, code: int = 1) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def parse_viewbox(spec: dict[str, Any]) -> tuple[int, int]:
    raw = spec.get("viewBox", "0 0 1280 800")
    parts = str(raw).split()
    if len(parts) != 4:
        return 1280, 800
    try:
        return int(float(parts[2])), int(float(parts[3]))
    except ValueError:
        return 1280, 800


def style_for_node(node: dict[str, Any]) -> str:
    base = NODE_STYLES.get(node.get("kind", "process"), NODE_STYLES["process"])
    overrides = node.get("style_overrides")
    return f"{base};{overrides}" if overrides else base


def style_for_edge(arrow: dict[str, Any]) -> str:
    base = EDGE_STYLES.get(arrow.get("kind", "control"), EDGE_STYLES["control"])
    parts = [base]

    exit_port = arrow.get("exit_port")
    if exit_port and exit_port in PORTS:
        ex, ey = PORTS[exit_port]
        parts.append(f"exitX={ex};exitY={ey};exitDx=0;exitDy=0")

    entry_port = arrow.get("entry_port")
    if entry_port and entry_port in PORTS:
        ex, ey = PORTS[entry_port]
        parts.append(f"entryX={ex};entryY={ey};entryDx=0;entryDy=0")

    if arrow.get("style_overrides"):
        parts.append(arrow["style_overrides"])

    return ";".join(parts) + ";"


def style_for_container(container: dict[str, Any]) -> str:
    overrides = container.get("style_overrides")
    return f"{CONTAINER_STYLE};{overrides}" if overrides else CONTAINER_STYLE


def render_node_label(label: str) -> str:
    # draw.io renders newlines in cell values when the cell has html=1.
    # The value attribute is XML; `<br/>` must be entity-encoded so the XML
    # parser accepts it. drawio unescapes `&lt;br/&gt;` back to `<br/>` and
    # renders it as a line break inside the cell.
    return escape(label).replace("\n", "&lt;br/&gt;")


def render_edge_waypoints(waypoints: list[dict[str, float]]) -> str:
    if not waypoints:
        return ""
    points = "".join(
        f'<mxPoint x="{int(p["x"])}" y="{int(p["y"])}" />' for p in waypoints
    )
    return f'<Array as="points">{points}</Array>'


def render_legend(
    spec: dict[str, Any],
    width: int,
    height: int,
    diagram_id: str,
) -> list[str]:
    items = spec.get("legend", [])
    if not items:
        return []

    pos = spec.get("legend_position", {})
    x = int(pos.get("x", 40))
    y = int(pos.get("y", height - 40))
    box_w = int(pos.get("width", width - 80))
    item_w = int(pos.get("item_width", 180))
    box_h = int(pos.get("height", 28))

    cells: list[str] = [
        f'<mxCell id="legend-box-{diagram_id}" value="" '
        f'style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#e2e8f0;" '
        f'vertex="1" parent="1">'
        f'<mxGeometry x="{x}" y="{y}" width="{box_w}" height="{box_h}" as="geometry" />'
        "</mxCell>"
    ]

    for idx, item in enumerate(items):
        item_x = x + 14 + idx * item_w
        swatch_y = y + 12
        label = escape(str(item.get("label", "")))
        kind = str(item.get("kind", "control"))
        color = item.get("color") or LEGEND_KIND_COLORS.get(kind, "#64748b")
        cells.append(
            f'<mxCell id="legend-swatch-{idx}-{diagram_id}" value="" '
            f'style="rounded=0;whiteSpace=wrap;html=1;fillColor={escape(color)};strokeColor={escape(color)};fontColor=#ffffff;" '
            f'vertex="1" parent="1">'
            f'<mxGeometry x="{item_x}" y="{swatch_y}" width="28" height="4" as="geometry" />'
            "</mxCell>"
        )
        cells.append(
            f'<mxCell id="legend-label-{idx}-{diagram_id}" value="{label}" '
            f'style="text;html=1;align=left;verticalAlign=middle;fontSize=11;fontColor=#0f172a;" '
            f'vertex="1" parent="1">'
            f'<mxGeometry x="{item_x + 36}" y="{y + 4}" width="{item_w - 42}" height="20" as="geometry" />'
            "</mxCell>"
        )

    return cells


def lane_waypoints(
    arrow: dict[str, Any],
    node_map: dict[str, dict[str, Any]],
) -> list[dict[str, float]]:
    """Compute corridor waypoints from a `lane` integer when no explicit
    waypoints were supplied.

    Lanes apply only to L↔L and R↔R routes (the common feedback-loop case).
    Lane 1 sits closest to the source/target nodes; lane N sits N-1 lane
    widths farther into the margin. This is the auto-stagger fix for the
    label-stacking problem that v1.2.0 surfaced when 5+ feedback arrows
    shared a single corridor.

    Returns an empty list when:
      - lane is absent or 0
      - explicit waypoints already supplied (caller wins)
      - exit_port and entry_port aren't both L or both R
      - source or target node is not in node_map
    """
    if arrow.get("waypoints"):
        return []
    lane = arrow.get("lane")
    if not lane or not isinstance(lane, (int, float)) or lane <= 0:
        return []

    exit_port = arrow.get("exit_port")
    entry_port = arrow.get("entry_port")
    if exit_port != entry_port or exit_port not in {"L", "R"}:
        return []

    src = node_map.get(arrow["source"])
    tgt = node_map.get(arrow["target"])
    if not src or not tgt:
        return []

    src_y = float(src["y"]) + float(src["height"]) / 2
    tgt_y = float(tgt["y"]) + float(tgt["height"]) / 2
    offset = LANE_BASE_OFFSET + (lane - 1) * LANE_SPACING

    if exit_port == "L":
        # Closest lane sits left of whichever node is further-left, so the
        # corridor stays outside both nodes' bounding boxes.
        corridor_x = min(float(src["x"]), float(tgt["x"])) - offset
    else:  # "R"
        corridor_x = max(
            float(src["x"]) + float(src["width"]),
            float(tgt["x"]) + float(tgt["width"]),
        ) + offset

    return [
        {"x": corridor_x, "y": src_y},
        {"x": corridor_x, "y": tgt_y},
    ]


def build_drawio(spec: dict[str, Any]) -> str:
    width, height = parse_viewbox(spec)
    title = spec.get("title", "Diagram")
    diagram_id = uuid.uuid4().hex[:16]

    cells: list[str] = []
    cells.append('<mxCell id="0" />')
    cells.append('<mxCell id="1" parent="0" />')

    containers = spec.get("containers", [])
    nodes = spec.get("nodes", [])
    arrows = spec.get("arrows", [])

    # node_map is needed by lane_waypoints to resolve source/target geometry.
    node_map: dict[str, dict[str, Any]] = {n["id"]: n for n in nodes}

    seen_ids: set[str] = set()
    for idx, c in enumerate(containers):
        cid = c.get("id") or f"container-{idx}-{diagram_id}"
        if cid in seen_ids:
            fail(f"duplicate node id: {cid}")
        seen_ids.add(cid)
        cells.append(
            f'<mxCell id="{escape(cid)}" value="{render_node_label(c.get("label", ""))}" '
            f'style="{escape(style_for_container(c))}" vertex="1" parent="1">'
            f'<mxGeometry x="{int(c["x"])}" y="{int(c["y"])}" '
            f'width="{int(c["width"])}" height="{int(c["height"])}" as="geometry" />'
            "</mxCell>"
        )

    for n in nodes:
        nid = n["id"]
        if nid in seen_ids:
            fail(f"duplicate node id: {nid}")
        seen_ids.add(nid)
        cells.append(
            f'<mxCell id="{escape(nid)}" value="{render_node_label(n.get("label", ""))}" '
            f'style="{escape(style_for_node(n))}" vertex="1" parent="1">'
            f'<mxGeometry x="{int(n["x"])}" y="{int(n["y"])}" '
            f'width="{int(n["width"])}" height="{int(n["height"])}" as="geometry" />'
            "</mxCell>"
        )

    # Title block as a non-interactive text node at the top of the canvas.
    if title:
        cells.append(
            f'<mxCell id="title-{diagram_id}" value="{escape(title)}" '
            f'style="text;html=1;align=center;verticalAlign=middle;fontSize=20;fontStyle=1;" '
            f'vertex="1" parent="1">'
            f'<mxGeometry x="40" y="10" width="{width - 80}" height="30" as="geometry" />'
            "</mxCell>"
        )
    if spec.get("subtitle"):
        cells.append(
            f'<mxCell id="subtitle-{diagram_id}" value="{escape(spec["subtitle"])}" '
            f'style="text;html=1;align=center;verticalAlign=middle;fontSize=12;fontStyle=2;fontColor=#555555;" '
            f'vertex="1" parent="1">'
            f'<mxGeometry x="40" y="38" width="{width - 80}" height="24" as="geometry" />'
            "</mxCell>"
        )

    edge_counter = 0
    for a in arrows:
        if a["source"] not in seen_ids or a["target"] not in seen_ids:
            fail(f"edge references missing node: {a['source']} -> {a['target']}")
        edge_counter += 1
        eid = f"e{edge_counter}-{diagram_id}"
        label = render_node_label(a.get("label", ""))
        # Auto-stagger via lane field. Explicit waypoints take precedence;
        # lane_waypoints returns [] when the arrow already has them.
        waypoints = a.get("waypoints") or lane_waypoints(a, node_map)
        wp = render_edge_waypoints(waypoints)
        cells.append(
            f'<mxCell id="{eid}" value="{label}" '
            f'style="{escape(style_for_edge(a))}" edge="1" parent="1" '
            f'source="{escape(a["source"])}" target="{escape(a["target"])}">'
            f'<mxGeometry relative="1" as="geometry">{wp}</mxGeometry>'
            "</mxCell>"
        )

    cells.extend(render_legend(spec, width, height, diagram_id))

    cells_xml = "\n        ".join(cells)
    # Page width/height matches viewBox so there's no excess whitespace.
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="prima-delivery/diagramming" version="1.0">
  <diagram id="{diagram_id}" name="{escape(title)}">
    <mxGraphModel dx="{width}" dy="{height}" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="{width}" pageHeight="{height}" math="0" shadow="0">
      <root>
        {cells_xml}
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
"""


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: build-drawio.py <input.json> <output.drawio>")
    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    if not in_path.is_file():
        fail(f"input not found: {in_path}")
    with in_path.open("r", encoding="utf-8") as f:
        spec = json.load(f)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(build_drawio(spec), encoding="utf-8")
    print(
        f"wrote {out_path} "
        f"({len(spec.get('nodes', []))} nodes, "
        f"{len(spec.get('arrows', []))} edges, "
        f"{len(spec.get('containers', []))} containers)"
    )


if __name__ == "__main__":
    main()
