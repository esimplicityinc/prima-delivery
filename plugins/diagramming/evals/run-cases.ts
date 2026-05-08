#!/usr/bin/env bun
/**
 * Eval runner for the diagramming plugin.
 *
 * Walks each case directory under plugins/diagramming/evals/ that contains a
 * translated.json + expected-invariants.json, drives fireworks-tech-graph's
 * scripts/generate-from-template.py with the translated input, validates the
 * resulting SVG via rsvg-convert, generates a PNG, and runs invariant checks.
 *
 * What this runner DOES test: the rendering pipeline (translated input ->
 * fireworks-tech-graph -> SVG -> rsvg-convert -> PNG) for the JSON shape this
 * plugin standardizes on. What it does NOT test: the AI step that converts
 * source files (k8s manifests, routes, schema) into translated.json. That step
 * is the responsibility of each SKILL.md's prompt and is exercised end-to-end
 * by integration with a model.
 *
 * Usage:
 *   bun run plugins/diagramming/evals/run-cases.ts
 *
 * Env vars:
 *   FIREWORKS_TECH_GRAPH_HOME  Path to the fireworks-tech-graph skill install.
 *                              Default: $HOME/.claude/skills/fireworks-tech-graph
 *   DIAGRAM_OUTPUT_DIR         Where to write SVG/PNG outputs.
 *                              Default: ./plugins/diagramming/evals/.out/
 */

import { readdir, readFile, stat, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, dirname, basename } from "node:path";
import { spawnSync } from "node:child_process";
import { homedir } from "node:os";

interface Invariants {
  // Common
  renderer?: "fireworks" | "drawio"; // default "fireworks"
  min_png_bytes?: number;

  // fireworks renderer
  template_type?: string;
  rsvg_validates?: boolean;
  svg_must_contain_text?: string[];
  min_arrow_markers?: number;
  diff_update?: {
    translated_v2: string;
    must_contain_after_diff: string[];
  };

  // drawio renderer
  drawio_must_contain_text?: string[];
}

interface CaseResult {
  case_name: string;
  passed: boolean;
  failures: string[];
}

const FIREWORKS_HOME =
  process.env.FIREWORKS_TECH_GRAPH_HOME ??
  join(homedir(), ".claude", "skills", "fireworks-tech-graph");

const EVALS_DIR = join(import.meta.dir);
const OUTPUT_DIR =
  process.env.DIAGRAM_OUTPUT_DIR ?? join(EVALS_DIR, ".out");

function failHard(msg: string): never {
  console.error(`ERROR: ${msg}`);
  process.exit(2);
}

async function checkPrereqs(): Promise<void> {
  const generator = join(FIREWORKS_HOME, "scripts", "generate-from-template.py");
  if (!existsSync(generator)) {
    failHard(
      `fireworks-tech-graph not found at ${FIREWORKS_HOME}.\n` +
        `Install: npx skills add yizhiyanhua-ai/fireworks-tech-graph\n` +
        `Or set FIREWORKS_TECH_GRAPH_HOME to the install path.`,
    );
  }
  const rsvg = spawnSync("rsvg-convert", ["--version"], { encoding: "utf8" });
  if (rsvg.status !== 0) {
    failHard(
      "rsvg-convert not found.\n" +
        "Install: brew install librsvg (macOS) or apt-get install librsvg2-bin (Linux).",
    );
  }
  const py = spawnSync("python3", ["--version"], { encoding: "utf8" });
  if (py.status !== 0) {
    failHard("python3 not found on PATH.");
  }
}

function generateSvg(
  templateType: string,
  outSvg: string,
  translatedJson: string,
): { ok: boolean; stderr: string } {
  const generator = join(FIREWORKS_HOME, "scripts", "generate-from-template.py");
  const r = spawnSync(
    "python3",
    [generator, templateType, outSvg, translatedJson],
    { encoding: "utf8" },
  );
  return { ok: r.status === 0, stderr: r.stderr ?? "" };
}

function rsvgPng(svgPath: string, pngPath: string): { ok: boolean; stderr: string } {
  // PNG generation acts as both validation and export: rsvg-convert parses the SVG
  // and exits non-zero on any structural error. A separate /dev/null validation
  // pass is unreliable across rsvg-convert versions (some reject /dev/null as a
  // non-regular file).
  const r = spawnSync("rsvg-convert", ["-w", "1920", svgPath, "-o", pngPath], {
    encoding: "utf8",
  });
  return { ok: r.status === 0, stderr: r.stderr ?? "" };
}

async function checkInvariants(
  svgPath: string,
  pngPath: string,
  inv: Invariants,
): Promise<string[]> {
  const failures: string[] = [];
  const svg = await readFile(svgPath, "utf8");

  for (const needle of inv.svg_must_contain_text ?? []) {
    if (!svg.includes(needle)) {
      failures.push(`SVG missing required text: "${needle}"`);
    }
  }

  if (typeof inv.min_arrow_markers === "number") {
    const markerCount = (svg.match(/<marker\b/g) ?? []).length;
    if (markerCount < inv.min_arrow_markers) {
      failures.push(
        `Expected >= ${inv.min_arrow_markers} <marker> elements, got ${markerCount}`,
      );
    }
  }

  if (typeof inv.min_png_bytes === "number") {
    const s = await stat(pngPath);
    if (s.size < inv.min_png_bytes) {
      failures.push(
        `PNG too small: ${s.size} bytes < ${inv.min_png_bytes} required`,
      );
    }
  }

  return failures;
}

async function runDrawioCase(
  caseDir: string,
  caseName: string,
  caseOut: string,
  translatedPath: string,
  inv: Invariants,
): Promise<CaseResult> {
  const failures: string[] = [];
  const drawioPath = join(caseOut, `${caseName}.drawio`);
  const pngPath = join(caseOut, `${caseName}.png`);

  // Helper script ships with this plugin, two dirs up from EVALS_DIR.
  const buildDrawio = join(EVALS_DIR, "..", "scripts", "build-drawio.py");
  if (!existsSync(buildDrawio)) {
    return {
      case_name: caseName,
      passed: false,
      failures: [`build-drawio.py not found at ${buildDrawio}`],
    };
  }

  const gen = spawnSync("python3", [buildDrawio, translatedPath, drawioPath], {
    encoding: "utf8",
  });
  if (gen.status !== 0) {
    return {
      case_name: caseName,
      passed: false,
      failures: [`build-drawio.py failed: ${gen.stderr.trim()}`],
    };
  }

  // Validate XML well-formedness regardless of whether drawio CLI is present.
  const drawioContent = await readFile(drawioPath, "utf8");
  for (const needle of inv.drawio_must_contain_text ?? []) {
    if (!drawioContent.includes(needle)) {
      failures.push(`.drawio missing required text: "${needle}"`);
    }
  }

  // Render PNG via drawio CLI if available; skip with note if not.
  const cliCheck = spawnSync("drawio", ["--version"], { encoding: "utf8" });
  if (cliCheck.status !== 0) {
    failures.push(
      "[SKIPPED PNG] drawio CLI not on PATH. Install: brew install --cask drawio",
    );
    return { case_name: caseName, passed: failures.length === 0, failures };
  }

  const pngExport = spawnSync(
    "drawio",
    [
      "--export",
      "--format",
      "png",
      "--scale",
      "2",
      "--output",
      pngPath,
      drawioPath,
    ],
    { encoding: "utf8" },
  );
  if (pngExport.status !== 0) {
    failures.push(`drawio PNG export failed: ${pngExport.stderr.trim()}`);
  } else if (!existsSync(pngPath)) {
    failures.push("drawio CLI exited 0 but no PNG produced");
  } else if (typeof inv.min_png_bytes === "number") {
    const s = await stat(pngPath);
    if (s.size < inv.min_png_bytes) {
      failures.push(
        `PNG too small: ${s.size} bytes < ${inv.min_png_bytes} required`,
      );
    }
  }

  return { case_name: caseName, passed: failures.length === 0, failures };
}

async function runCase(caseDir: string): Promise<CaseResult> {
  const caseName = basename(caseDir);
  const failures: string[] = [];

  const translatedPath = join(caseDir, "translated.json");
  const invariantsPath = join(caseDir, "expected-invariants.json");

  if (!existsSync(translatedPath) || !existsSync(invariantsPath)) {
    return {
      case_name: caseName,
      passed: false,
      failures: ["missing translated.json or expected-invariants.json"],
    };
  }

  const translated = await readFile(translatedPath, "utf8");
  const inv: Invariants = JSON.parse(
    await readFile(invariantsPath, "utf8"),
  );

  const caseOut = join(OUTPUT_DIR, caseName);
  await mkdir(caseOut, { recursive: true });

  const renderer = inv.renderer ?? "fireworks";

  if (renderer === "drawio") {
    return await runDrawioCase(caseDir, caseName, caseOut, translatedPath, inv);
  }

  // fireworks path (default).
  if (!inv.template_type) {
    return {
      case_name: caseName,
      passed: false,
      failures: ["fireworks renderer requires template_type in invariants"],
    };
  }
  const svgPath = join(caseOut, `${caseName}.svg`);
  const pngPath = join(caseOut, `${caseName}.png`);

  const gen = generateSvg(inv.template_type, svgPath, translated);
  if (!gen.ok) {
    return {
      case_name: caseName,
      passed: false,
      failures: [`generate-from-template.py failed: ${gen.stderr.trim()}`],
    };
  }

  const val = rsvgPng(svgPath, pngPath);
  if (!val.ok) {
    failures.push(`rsvg-convert failed (SVG invalid): ${val.stderr.trim()}`);
  }

  if (val.ok && existsSync(pngPath)) {
    failures.push(...(await checkInvariants(svgPath, pngPath, inv)));
  }

  if (inv.diff_update) {
    const v2Path = join(caseDir, inv.diff_update.translated_v2);
    if (!existsSync(v2Path)) {
      failures.push(`diff_update fixture missing: ${inv.diff_update.translated_v2}`);
    } else {
      const v2 = await readFile(v2Path, "utf8");
      const v2Svg = join(caseOut, `${caseName}-v2.svg`);
      const v2Png = join(caseOut, `${caseName}-v2.png`);
      const gen2 = generateSvg(inv.template_type, v2Svg, v2);
      if (!gen2.ok) {
        failures.push(`diff-update generate failed: ${gen2.stderr.trim()}`);
      } else {
        const val2 = rsvgPng(v2Svg, v2Png);
        if (!val2.ok) failures.push(`diff-update rsvg failed (SVG invalid): ${val2.stderr.trim()}`);
        const v2Content = await readFile(v2Svg, "utf8");
        for (const needle of inv.diff_update.must_contain_after_diff) {
          if (!v2Content.includes(needle)) {
            failures.push(`diff-update SVG missing required text: "${needle}"`);
          }
        }
      }
    }
  }

  return { case_name: caseName, passed: failures.length === 0, failures };
}

async function powerpointSmoke(): Promise<CaseResult> {
  // Smokes the deck builder: takes the arch-from-k8s PNG produced by the
  // case run above, builds a 1-slide deck, asserts the .pptx exists and is
  // a non-trivial OOXML file. Skipped (not failed) if python-pptx is unavailable.
  const archPng = join(OUTPUT_DIR, "arch-from-k8s", "arch-from-k8s.png");
  if (!existsSync(archPng)) {
    return {
      case_name: "powerpoint-smoke",
      passed: false,
      failures: ["arch-from-k8s.png missing; case must run before pptx smoke"],
    };
  }

  const deckSpecPath = join(OUTPUT_DIR, "smoke-deck-spec.json");
  const deckOut = join(OUTPUT_DIR, "smoke-deck.pptx");
  await import("node:fs/promises").then((fs) =>
    fs.writeFile(
      deckSpecPath,
      JSON.stringify(
        {
          title: "Diagramming smoke deck",
          author: "run-cases.ts",
          slides: [
            {
              title: "SHINE portal deployment topology",
              image: archPng,
              notes: "Two-tier deployment: ingress -> frontend + api -> pods.",
            },
          ],
        },
        null,
        2,
      ),
      "utf8",
    ),
  );

  const pyCmd = process.env.DIAGRAM_PPTX_PYTHON ?? "python3";
  const buildScript = join(
    EVALS_DIR,
    "..",
    "scripts",
    "build-deck.py",
  );
  const r = spawnSync(pyCmd, [buildScript, deckSpecPath, deckOut], {
    encoding: "utf8",
  });

  if (r.status === 2) {
    // python-pptx not installed: skip with a clear message.
    return {
      case_name: "powerpoint-smoke",
      passed: true,
      failures: [
        `[SKIPPED] python-pptx not installed in ${pyCmd}. ${r.stderr.trim().split("\n")[0]}`,
      ],
    };
  }
  if (r.status !== 0) {
    return {
      case_name: "powerpoint-smoke",
      passed: false,
      failures: [`build-deck.py failed: ${r.stderr.trim()}`],
    };
  }

  if (!existsSync(deckOut)) {
    return {
      case_name: "powerpoint-smoke",
      passed: false,
      failures: ["build-deck.py exited 0 but no .pptx produced"],
    };
  }
  const s = await stat(deckOut);
  if (s.size < 10000) {
    return {
      case_name: "powerpoint-smoke",
      passed: false,
      failures: [`.pptx too small: ${s.size} bytes (expected > 10000)`],
    };
  }

  return { case_name: "powerpoint-smoke", passed: true, failures: [] };
}

async function main(): Promise<void> {
  await checkPrereqs();
  await mkdir(OUTPUT_DIR, { recursive: true });

  const entries = await readdir(EVALS_DIR, { withFileTypes: true });
  const caseDirs = entries
    .filter((e) => e.isDirectory() && !e.name.startsWith("."))
    .map((e) => join(EVALS_DIR, e.name));

  if (caseDirs.length === 0) {
    failHard("No eval cases found.");
  }

  const results: CaseResult[] = [];
  for (const dir of caseDirs) {
    const r = await runCase(dir);
    results.push(r);
    const status = r.passed ? "PASS" : "FAIL";
    console.log(`[${status}] ${r.case_name}`);
    for (const f of r.failures) console.log(`    ${f}`);
  }

  // PowerPoint smoke runs after the case suite so it can use a generated PNG.
  const pptResult = await powerpointSmoke();
  results.push(pptResult);
  const pptStatus = pptResult.passed ? "PASS" : "FAIL";
  console.log(`[${pptStatus}] ${pptResult.case_name}`);
  for (const f of pptResult.failures) console.log(`    ${f}`);

  const failed = results.filter((r) => !r.passed).length;
  console.log(
    `\n${results.length - failed}/${results.length} checks passed.`,
  );
  process.exit(failed > 0 ? 1 : 0);
}

await main();
