#!/usr/bin/env node
/**
 * Build a multi-slide PowerPoint deck via PptxGenJS - the path Anthropic's
 * pptx skill recommends for from-scratch deck creation
 * (anthropics/skills/skills/pptx/pptxgenjs.md).
 *
 * Replaces the v1.4.0 python-pptx implementation. python-pptx works but
 * its default master inherits Times New Roman + minimal layout, which is
 * not appropriate for customer-facing decks. PptxGenJS lets us define a
 * proper visual language once (title bar, image scaling, footer) and
 * apply it consistently across every slide.
 *
 * This script is invoked as a subprocess by the architecture-diagrams and
 * flow-diagrams skills when their input contract has `mode: "powerpoint"`.
 * It is NOT a Node library - standalone CLI.
 *
 * Usage:
 *   node build-deck.js <deck-spec.json> <output.pptx>
 *
 * deck-spec.json shape (compatible with the v1.4.0 python-pptx version):
 *   {
 *     "title":  "Deck title",
 *     "author": "Optional attribution",
 *     "slides": [
 *       {
 *         "title":    "Slide title",
 *         "subtitle": "Optional subtitle in the title bar",
 *         "image":    "../diagrams/my-diagram.png",
 *         "notes":    "Speaker notes."
 *       }
 *     ]
 *   }
 *
 * Reference architecture posture: no hardcoded paths. Reads paths from argv
 * and the input JSON only. Relative slide image paths resolve from the deck
 * spec directory so committed sample specs are portable across machines.
 */

"use strict";

const fs = require("fs");
const path = require("path");
const PptxGenJS = require("pptxgenjs");

function fail(msg, code = 1) {
  process.stderr.write(`ERROR: ${msg}\n`);
  process.exit(code);
}

if (process.argv.length !== 4) {
  fail("usage: node build-deck.js <deck-spec.json> <output.pptx>");
}

const [, , specPath, outPath] = process.argv;
const specDir = path.dirname(path.resolve(specPath));

if (!fs.existsSync(specPath) || !fs.statSync(specPath).isFile()) {
  fail(`spec not found: ${specPath}`);
}

const spec = JSON.parse(fs.readFileSync(specPath, "utf8"));
const deckTitle = spec.title || "Diagrams";
const author = spec.author || "";
const slides = spec.slides || [];

if (slides.length === 0) {
  fail("deck spec has no slides");
}

function resolveSlideImage(rawImage, slideTitle) {
  if (typeof rawImage !== "string" || rawImage.trim() === "") {
    fail(`image missing for slide '${slideTitle}'`);
  }
  return path.isAbsolute(rawImage)
    ? rawImage
    : path.resolve(specDir, rawImage);
}

// Visual language - defined once, applied to every slide.
const FONT = "Helvetica Neue";
const TITLE_FONT_SIZE = 24;
const SUBTITLE_FONT_SIZE = 12;
const FOOTER_FONT_SIZE = 9;
const BAR_FILL = "0D47A1"; // blue 900
const BAR_FG = "FFFFFF";
const FOOTER_FG = "555555";
const SUBTITLE_FG = "E3F2FD"; // light blue, sits inside the bar

// Slide dims for LAYOUT_WIDE: 13.3" × 7.5".
const SLIDE_W = 13.3;
const SLIDE_H = 7.5;
const TITLE_BAR_H = 0.85;
const FOOTER_H = 0.35;
const SIDE_MARGIN = 0.4;
const IMAGE_TOP_MARGIN = 0.18;

const pres = new PptxGenJS();
pres.layout = "LAYOUT_WIDE";
pres.author = author || "prima-delivery diagramming plugin";
pres.title = deckTitle;
pres.subject = deckTitle;

// Title slide - only when the deck is meaningfully multi-slide.
// Single-slide decks have no use for a title card; it's just dead weight.
const includeTitleSlide = slides.length >= 3;

if (includeTitleSlide) {
  const titleSlide = pres.addSlide();
  // Background - soft cream, lets the navy title pop without being austere.
  titleSlide.background = { color: "FAFAFA" };
  titleSlide.addText(deckTitle, {
    x: SIDE_MARGIN,
    y: SLIDE_H / 2 - 1.2,
    w: SLIDE_W - 2 * SIDE_MARGIN,
    h: 1.2,
    align: "center",
    valign: "middle",
    fontFace: FONT,
    fontSize: 44,
    bold: true,
    color: BAR_FILL,
  });
  if (author) {
    titleSlide.addText(author, {
      x: SIDE_MARGIN,
      y: SLIDE_H / 2 + 0.6,
      w: SLIDE_W - 2 * SIDE_MARGIN,
      h: 0.6,
      align: "center",
      valign: "top",
      fontFace: FONT,
      fontSize: 18,
      color: "6B7280",
    });
  }
}

function imageDimensions(imgPath) {
  // PptxGenJS preserves aspect via sizing options. For the 'cover'-fit math we
  // need the image's pixel dimensions. PNG has them in bytes 16..24.
  const buf = fs.readFileSync(imgPath);
  if (buf.toString("ascii", 1, 4) !== "PNG") {
    // Fallback: assume a 16:9 aspect; let PptxGenJS scale to bounding box.
    return { w: 1920, h: 1080 };
  }
  return {
    w: buf.readUInt32BE(16),
    h: buf.readUInt32BE(20),
  };
}

for (let i = 0; i < slides.length; i++) {
  const s = slides[i];
  const slide = pres.addSlide();
  const sTitle = s.title || `Slide ${i + 1}`;
  const sSubtitle = s.subtitle || "";
  const sImage = resolveSlideImage(s.image, sTitle);
  const sNotes = s.notes || "";

  if (!sImage || !fs.existsSync(sImage)) {
    fail(`image not found for slide '${sTitle}': ${sImage}`);
  }

  // Title bar - solid blue rectangle full-width.
  slide.addShape(pres.ShapeType.rect, {
    x: 0,
    y: 0,
    w: SLIDE_W,
    h: TITLE_BAR_H,
    fill: { color: BAR_FILL },
    line: { color: BAR_FILL, width: 0 },
  });

  // Title text inside the bar.
  slide.addText(sTitle, {
    x: 0.5,
    y: 0.05,
    w: SLIDE_W - 1.0,
    h: sSubtitle ? TITLE_BAR_H * 0.55 : TITLE_BAR_H,
    valign: sSubtitle ? "bottom" : "middle",
    fontFace: FONT,
    fontSize: TITLE_FONT_SIZE,
    bold: true,
    color: BAR_FG,
    margin: 0,
  });

  if (sSubtitle) {
    slide.addText(sSubtitle, {
      x: 0.5,
      y: TITLE_BAR_H * 0.55,
      w: SLIDE_W - 1.0,
      h: TITLE_BAR_H * 0.45 - 0.05,
      valign: "top",
      fontFace: FONT,
      fontSize: SUBTITLE_FONT_SIZE,
      color: SUBTITLE_FG,
      italic: true,
      margin: 0,
    });
  }

  // Image - preserve aspect, fit within the body region with margin.
  const bodyTop = TITLE_BAR_H + IMAGE_TOP_MARGIN;
  const bodyW = SLIDE_W - 2 * SIDE_MARGIN;
  const bodyH = SLIDE_H - TITLE_BAR_H - FOOTER_H - 2 * IMAGE_TOP_MARGIN;
  const imgDims = imageDimensions(sImage);
  const imgAspect = imgDims.w / imgDims.h;
  const bodyAspect = bodyW / bodyH;
  let dispW;
  let dispH;
  if (imgAspect > bodyAspect) {
    dispW = bodyW;
    dispH = dispW / imgAspect;
  } else {
    dispH = bodyH;
    dispW = dispH * imgAspect;
  }
  const offX = SIDE_MARGIN + (bodyW - dispW) / 2;
  const offY = bodyTop + (bodyH - dispH) / 2;

  slide.addImage({
    path: sImage,
    x: offX,
    y: offY,
    w: dispW,
    h: dispH,
  });

  // Footer - deck title left, slide number right.
  slide.addText(deckTitle + (author ? `   ·   ${author}` : ""), {
    x: SIDE_MARGIN,
    y: SLIDE_H - FOOTER_H,
    w: SLIDE_W - 2 * SIDE_MARGIN - 1.5,
    h: FOOTER_H,
    valign: "middle",
    fontFace: FONT,
    fontSize: FOOTER_FONT_SIZE,
    color: FOOTER_FG,
    margin: 0,
  });
  slide.addText(`${i + 1} / ${slides.length}`, {
    x: SLIDE_W - SIDE_MARGIN - 1.5,
    y: SLIDE_H - FOOTER_H,
    w: 1.5,
    h: FOOTER_H,
    align: "right",
    valign: "middle",
    fontFace: FONT,
    fontSize: FOOTER_FONT_SIZE,
    color: FOOTER_FG,
    margin: 0,
  });

  if (sNotes) {
    slide.addNotes(sNotes);
  }
}

// PptxGenJS writeFile is async; wrap in IIFE to await. Catch + exit non-zero
// on failure so eval runners and CI see a real failure signal instead of an
// UnhandledPromiseRejection warning that leaves exit code at 0.
(async () => {
  try {
    await pres.writeFile({ fileName: outPath });
    const numSlides = slides.length;
    const titleNote = includeTitleSlide ? `, + title card` : "";
    process.stdout.write(
      `wrote ${outPath} (${numSlides} content slide${numSlides !== 1 ? "s" : ""}${titleNote})\n`,
    );
  } catch (err) {
    fail(`writeFile failed: ${err && err.message ? err.message : err}`);
  }
})();
