#!/usr/bin/env python3
"""
Assemble a PowerPoint deck from a list of diagrams.

This script is invoked by the architecture-diagrams and flow-diagrams skills
when their input contract has `mode: "powerpoint"`. It is NOT a Python library
and is not imported by any other Python code in the plugin; it is a standalone
helper invoked via subprocess.

Usage:
  python3 build-deck.py <deck-spec.json> <output.pptx>

deck-spec.json shape:
  {
    "title":  "Deck title (becomes the title slide)",
    "theme":  "default",
    "author": "Author name (optional, goes in slide footer)",
    "slides": [
      {
        "title": "Slide title",
        "image": "/abs/path/to/diagram.png",
        "notes": "Speaker notes (textual description of the diagram)."
      }
    ]
  }

If python-pptx is not available on the active python3, the script exits with
code 2 and prints an install hint. Skills should surface that error verbatim
to the user.

Reference architecture posture: no hardcoded paths. The script reads paths
from deck-spec.json and writes to the path in argv[2]. The caller controls
both.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

INSTALL_HINT = (
    "python-pptx is not installed in the active python3.\n"
    "Install options:\n"
    "  - venv (recommended for the plugin): "
    "python3 -m venv /path/to/venv && /path/to/venv/bin/pip install python-pptx, "
    "then set DIAGRAM_PPTX_PYTHON=/path/to/venv/bin/python3\n"
    "  - pipx (if pipx-installed deck builder is acceptable): "
    "pipx run --spec python-pptx python-pptx (not standard; venv is cleaner)\n"
    "  - system pip (last resort, may need --break-system-packages on PEP 668 platforms)"
)


def fail(msg: str, code: int = 1) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: build-deck.py <deck-spec.json> <output.pptx>")

    spec_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])

    if not spec_path.is_file():
        fail(f"deck spec not found: {spec_path}")

    try:
        # Imported at runtime so the install-hint error message is reachable
        # even when the import itself fails.
        from pptx import Presentation
        from pptx.util import Inches, Pt
    except ImportError:
        fail(INSTALL_HINT, code=2)

    with spec_path.open("r", encoding="utf-8") as f:
        spec = json.load(f)

    title = spec.get("title", "Diagrams")
    author = spec.get("author")
    slides = spec.get("slides", [])

    if not slides:
        fail("deck spec has no slides")

    prs = Presentation()
    # 16:9 widescreen.
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)

    # Title slide.
    title_layout = prs.slide_layouts[0]
    title_slide = prs.slides.add_slide(title_layout)
    title_slide.shapes.title.text = title
    if author and len(title_slide.placeholders) > 1:
        title_slide.placeholders[1].text = author

    # One slide per diagram.
    blank_layout = prs.slide_layouts[5]  # Title only
    for i, slide_spec in enumerate(slides):
        s_title = slide_spec.get("title", f"Diagram {i + 1}")
        s_image = slide_spec.get("image")
        s_notes = slide_spec.get("notes", "")

        slide = prs.slides.add_slide(blank_layout)
        slide.shapes.title.text = s_title

        if s_image and Path(s_image).is_file():
            # Center the image under the title with a generous margin.
            # Slide is 13.333 x 7.5 inches; title sits ~0 to ~1.0 inch.
            left = Inches(0.5)
            top = Inches(1.2)
            width = Inches(12.333)  # leave 0.5in left/right margins
            slide.shapes.add_picture(s_image, left, top, width=width)
        else:
            # Image missing; surface as a visible note on the slide rather than failing
            # silently. This keeps a partial deck rather than no deck.
            from pptx.util import Inches as _Inches  # avoid shadowing
            tx = slide.shapes.add_textbox(_Inches(1), _Inches(3),
                                          _Inches(11), _Inches(1)).text_frame
            tx.text = f"Image not found: {s_image}"

        if s_notes:
            slide.notes_slide.notes_text_frame.text = s_notes

    out_path.parent.mkdir(parents=True, exist_ok=True)
    prs.save(str(out_path))
    print(f"wrote {out_path} ({len(slides)} slides)")


if __name__ == "__main__":
    main()
