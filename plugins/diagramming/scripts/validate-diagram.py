#!/usr/bin/env python3
"""
WCAG contrast validator for .drawio output.

Walks the .drawio XML, extracts each vertex cell's fillColor and fontColor,
computes the WCAG 2.x relative-luminance contrast ratio, and reports any
text/fill pair below the threshold (AA = 4.5, AAA = 7.0). Catches the
common failure mode where a custom `style_overrides` accidentally puts
dark text on a dark fill or light text on a light fill.

This is a deterministic local check — no rendering, no agent dispatch.
For full visual audit (typography readability, layout overlap, focus
indicators), the diagramming skills can additionally dispatch the
`ui-visual-validator` agent against the rendered PNG; that's a separate
phase. This script is the cheap first gate.

Usage:
  python3 validate-diagram.py <input.drawio> [--threshold 4.5]
  python3 validate-diagram.py <input.drawio> --json     # machine-readable

Exit codes:
  0 = all cells pass threshold
  1 = at least one cell fails threshold
  2 = malformed input or other usage error

Reference: WCAG 2.2 Section 1.4.3 (Contrast Minimum, AA = 4.5:1 for body
text, 3:1 for large text). We use 4.5 as the default for diagram labels
since most cell text is body-sized.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Iterable

# WCAG 2.x default thresholds.
THRESHOLD_AA = 4.5
THRESHOLD_AAA = 7.0

# drawio default text color when fontColor is unspecified in the style.
DEFAULT_FONT_COLOR = "#000000"
# drawio default fill when fillColor is unspecified.
DEFAULT_FILL = "#ffffff"


def parse_hex(color: str) -> tuple[int, int, int] | None:
    """Parse #rrggbb or #rgb into (r, g, b). Return None for keywords like
    "none" or unparseable strings."""
    if not color:
        return None
    color = color.strip().lower()
    if color in {"none", "transparent", "default"}:
        return None
    m = re.fullmatch(r"#?([0-9a-f]{6}|[0-9a-f]{3})", color)
    if not m:
        return None
    hexstr = m.group(1)
    if len(hexstr) == 3:
        hexstr = "".join(c * 2 for c in hexstr)
    return int(hexstr[0:2], 16), int(hexstr[2:4], 16), int(hexstr[4:6], 16)


def relative_luminance(rgb: tuple[int, int, int]) -> float:
    """WCAG 2.x relative luminance formula (sRGB)."""

    def channel(c: int) -> float:
        s = c / 255.0
        return s / 12.92 if s <= 0.03928 else ((s + 0.055) / 1.055) ** 2.4

    r, g, b = rgb
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast_ratio(c1: tuple[int, int, int], c2: tuple[int, int, int]) -> float:
    """WCAG 2.x contrast ratio. Range 1.0 (no contrast) to 21.0 (max)."""
    l1 = relative_luminance(c1)
    l2 = relative_luminance(c2)
    lighter, darker = (l1, l2) if l1 >= l2 else (l2, l1)
    return (lighter + 0.05) / (darker + 0.05)


def parse_style(style: str) -> dict[str, str]:
    """drawio styles are semicolon-separated key=value with bare shape names
    (e.g. "rounded=1;fillColor=#fff;rhombus") interspersed. Return only the
    key=value pairs."""
    out: dict[str, str] = {}
    for part in (style or "").split(";"):
        if "=" in part:
            k, _, v = part.partition("=")
            out[k.strip()] = v.strip()
    return out


def iter_vertex_cells(drawio_path: Path) -> Iterable[dict[str, str]]:
    """Yield {id, label, style} for every vertex cell in the file."""
    try:
        tree = ET.parse(drawio_path)
    except ET.ParseError as e:
        print(f"ERROR: malformed XML: {e}", file=sys.stderr)
        sys.exit(2)
    for cell in tree.iter("mxCell"):
        if cell.get("vertex") != "1":
            continue
        yield {
            "id": cell.get("id", "<no-id>"),
            "label": cell.get("value", "")[:60],
            "style": cell.get("style", ""),
        }


def check_cell(cell: dict[str, str], threshold: float) -> dict | None:
    """Return a finding dict if the cell fails threshold, else None."""
    style = parse_style(cell["style"])
    fill = style.get("fillColor", DEFAULT_FILL)
    font = style.get("fontColor", DEFAULT_FONT_COLOR)

    fill_rgb = parse_hex(fill)
    font_rgb = parse_hex(font)
    if not fill_rgb or not font_rgb:
        # Unparseable color (e.g., "none" for fill of an edge label background).
        # Skip — not a contrast violation.
        return None

    ratio = contrast_ratio(font_rgb, fill_rgb)
    if ratio >= threshold:
        return None
    return {
        "id": cell["id"],
        "label": cell["label"],
        "fill": fill,
        "font": font,
        "ratio": round(ratio, 2),
        "required": threshold,
    }


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    p.add_argument("input", type=Path, help=".drawio file to validate")
    p.add_argument(
        "--threshold",
        type=float,
        default=THRESHOLD_AA,
        help=f"WCAG contrast minimum (default {THRESHOLD_AA} for AA; use {THRESHOLD_AAA} for AAA)",
    )
    p.add_argument(
        "--json",
        action="store_true",
        help="machine-readable output",
    )
    args = p.parse_args()

    if not args.input.is_file():
        print(f"ERROR: not a file: {args.input}", file=sys.stderr)
        sys.exit(2)

    findings: list[dict] = []
    cell_count = 0
    for cell in iter_vertex_cells(args.input):
        cell_count += 1
        f = check_cell(cell, args.threshold)
        if f:
            findings.append(f)

    if args.json:
        print(
            json.dumps(
                {
                    "input": str(args.input),
                    "threshold": args.threshold,
                    "cells_checked": cell_count,
                    "findings": findings,
                    "passed": len(findings) == 0,
                },
                indent=2,
            )
        )
    else:
        if findings:
            print(
                f"FAIL: {len(findings)}/{cell_count} cells below WCAG {args.threshold}:1 contrast"
            )
            for f in findings:
                print(
                    f"  cell {f['id']!r:30s}  fill={f['fill']:8s} font={f['font']:8s}  "
                    f"ratio={f['ratio']}  (label: {f['label']!r})"
                )
        else:
            print(f"PASS: {cell_count} cells, all >= WCAG {args.threshold}:1 contrast")

    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
