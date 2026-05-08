#!/usr/bin/env python3
"""
Build a draw.io / diagrams.net XML file from the same nodes/arrows JSON shape
used by fireworks-tech-graph. Output is a `.drawio` file openable in
diagrams.net (web), draw.io desktop, or the VS Code drawio plugin.

Why a second renderer
---------------------
fireworks-tech-graph produces clean topology diagrams but its layout engine
struggles with dense feedback graphs (many backloop arrows on a single
spine — labels collide, lines overlap). draw.io has a mature routing engine
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
    ]
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


def build_drawio(spec: dict[str, Any]) -> str:
    width, height = parse_viewbox(spec)
    title = spec.get("title", "Diagram")
    diagram_id = uuid.uuid4().hex[:16]

    cells: list[str] = []
    cells.append('<mxCell id="0" />')
    cells.append('<mxCell id="1" parent="0" />')

    nodes = spec.get("nodes", [])
    arrows = spec.get("arrows", [])

    seen_ids: set[str] = set()
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
        wp = render_edge_waypoints(a.get("waypoints", []))
        cells.append(
            f'<mxCell id="{eid}" value="{label}" '
            f'style="{escape(style_for_edge(a))}" edge="1" parent="1" '
            f'source="{escape(a["source"])}" target="{escape(a["target"])}">'
            f'<mxGeometry relative="1" as="geometry">{wp}</mxGeometry>'
            "</mxCell>"
        )

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
    print(f"wrote {out_path} ({len(spec.get('nodes', []))} nodes, {len(spec.get('arrows', []))} edges)")


if __name__ == "__main__":
    main()
