# diagramming

Generate architecture, deployment, network, sequence, ERD, state machine, and flowchart diagrams as SVG / `.drawio` / PNG, with optional PowerPoint deck assembly. WCAG AA contrast validated.

Two skills (`architecture-diagrams`, `flow-diagrams`) and one routing agent (`diagramming-engineer`). Two interchangeable renderers (`fireworks-tech-graph` for clean topology, `drawio` for dense feedback graphs). Optional `powerpoint` mode that assembles renders into a single deck via PptxGenJS.

## Quick start

From the repo root:

```bash
just diagramming-bootstrap
```

That installs every dep this plugin needs (system binaries, the sibling skill, the npm package) and prints `OK` / `MISSING` for each. Run it once per machine.

To verify everything works end-to-end:

```bash
bun run plugins/diagramming/evals/run-cases.ts
bun run plugins/diagramming/evals/run-routing-eval.ts
```

You should see `8/8 checks passed.` and `[PASS] routing fixtures: 11 valid entries`.

## Dependencies

Four deps total. Three are system / external; one (`pptxgenjs`) is packaged.

| Dep | Required for | Install | Packaged? |
|---|---|---|---|
| `rsvg-convert` | SVG validation + PNG export from fireworks renderer | `brew install librsvg` (macOS) <br> `apt-get install librsvg2-bin` (Debian/Ubuntu) | No (system binary) |
| `python3` | fireworks-tech-graph helpers + drawio builder + WCAG validator | Standard on macOS / most Linux | No (system) |
| `node` 18+ | PptxGenJS deck builder | `brew install node` / nvm | No (system) |
| `fireworks-tech-graph` skill | Default renderer (SVG diagrams) | `npx skills add yizhiyanhua-ai/fireworks-tech-graph --force -g -y` | No (sibling skill, lives at `~/.agents/skills/fireworks-tech-graph/` for opencode users; `~/.claude/skills/fireworks-tech-graph/` for Claude Code users) |
| `pptxgenjs` (npm) | `mode: powerpoint` deck assembly | `cd plugins/diagramming && npm install` | Yes (declared in `package.json`) |
| `drawio` desktop CLI | PNG export from `.drawio` renderer (optional) | `brew install --cask drawio` | No (Electron app, ~200 MB) |

`just diagramming-bootstrap` runs the right install command per platform, then verifies each one.

### What works without each dep

The plugin degrades gracefully - you don't need all six to use most of it.

| Without... | You lose | You keep |
|---|---|---|
| `drawio` CLI | PNG export from `.drawio` files | `.drawio` XML output (open in diagrams.net web or VS Code drawio extension) |
| `pptxgenjs` | `mode: powerpoint` deck assembly | All `mode: plain` rendering (SVG, PNG, `.drawio`) |
| `fireworks-tech-graph` skill | Default SVG renderer | `.drawio` renderer (use `renderer: drawio` explicitly) |
| `rsvg-convert` | SVG validation + PNG export | `.drawio` renderer end-to-end |
| `node` | PptxGenJS smoke + deck mode | Everything else |

So the absolute minimum for a working install is `python3` + one of (`fireworks-tech-graph` + `rsvg-convert`) or (`drawio` CLI). Most teams want all of them.

## Usage

### Via the skills

Both skills load via opencode. Invoke them in prose:

```
> Diagram the SHINE portal deployment from infra/k8s/
```

The `diagramming-engineer` agent routes architecture vs. flow and decides plain vs. powerpoint mode based on the prompt. See `agents/diagramming-engineer.md` for the routing table.

If you want to bypass the router and call a skill directly:

```
> /architecture-diagrams generate from infra/k8s/*.yaml, output to ./diagrams/
```

See `skills/architecture-diagrams/SKILL.md` and `skills/flow-diagrams/SKILL.md` for the full input contract per skill.

### Via the helper scripts directly

Useful for scripting, CI, or when you already have a drawio `translated.json` (the structured node/edge spec) or a fireworks SVG composed by the skill:

```bash
SPEC=path/to/my-diagram.spec.json
OUT_DIR=path/to/output

# fireworks renderer
# The skill composes free-form SVG via fireworks-tech-graph's own SKILL.md.
# Direct helper usage should only validate and export that SVG.
rsvg-convert "$OUT_DIR/my-diagram.svg" -o /dev/null
rsvg-convert -w 1920 "$OUT_DIR/my-diagram.svg" -o "$OUT_DIR/my-diagram.png"

# drawio renderer (dense graphs, explicit lanes, named feedback loops)
python3 plugins/diagramming/scripts/build-drawio.py "$SPEC" "$OUT_DIR/my-diagram.drawio"
drawio --export --format png --scale 2 \
  --output "$OUT_DIR/my-diagram.png" "$OUT_DIR/my-diagram.drawio"

# WCAG AA contrast validation (always run for drawio outputs)
python3 plugins/diagramming/scripts/validate-diagram.py "$OUT_DIR/my-diagram.drawio"

# PowerPoint deck assembly (input shape: see plugins/diagramming/docs/decks/README.md)
node plugins/diagramming/scripts/build-deck.js deck-spec.json "$OUT_DIR/my-deck.pptx"
```

## Renderer choice

| Renderer | Output | When |
|---|---|---|
| `fireworks` | SVG + PNG | Simple architecture, sequence, ERD, and linear flow diagrams where labels and arrows do not need explicit routing. |
| `drawio` | `.drawio` XML + PNG | Dense deployment diagrams, CI/CD plus runtime diagrams, named feedback loops, hub-and-spoke topologies, and anything where labels or arrows collide. |

Override globally via `DIAGRAM_DEFAULT_RENDERER=drawio`, or per-invocation via the `renderer` field in the skill input.

When a generated diagram is ugly, do not patch the image by hand. Classify the graph, switch renderer when the class calls for it, and invoke the skill again. Tommy's PR #5 prompt is fenced by `evals/tommy-shine-deployment/`: `Diagram the SHINE portal deployment from ~/repos/content-portal` routes to `architecture-diagrams` with `renderer: drawio`.

## Visual verification

The plugin runs three layers of verification depending on use case.

| Layer | What | When |
|---|---|---|
| **A** - `validate-diagram.py` | WCAG 2.x contrast ratio per cell, deterministic, ~50 ms | Always run for drawio output. Catches dark-on-dark / light-on-light style overrides. |
| **B** - `ui-visual-validator` agent (in `plugins/accessibility-compliance/`) | Pixel-level audit: typography, layout density, color-blind safety beyond contrast | Customer-facing deliverables. |
| **C** - `katalyst-ux-audit` (in katalyst-taxonomy-agents) | Live screenshot + DTCG token output via Playwright | When the diagram is embedded in a deployed surface. |

Layer A is built into the eval suite via the `validate_contrast` invariant. Layers B and C are opt-in dispatch.

## Configuration

Every parameter is overridable via env var. Per CLAUDE.md, no hardcoded paths or project names anywhere in the plugin.

| Env var | Default | What |
|---|---|---|
| `DIAGRAM_OUTPUT_DIR` | `./diagrams/` | Where SVG/PNG/`.drawio`/`.pptx` artifacts land |
| `DIAGRAM_DEFAULT_RENDERER` | `fireworks` | `fireworks` or `drawio` |
| `DIAGRAM_DEFAULT_STYLE` | `1` | fireworks-tech-graph style (1-7) |
| `DIAGRAM_DECK_TITLE` | (required in powerpoint mode) | Title for the assembled deck |
| `FIREWORKS_TECH_GRAPH_HOME` | `~/.agents/skills/fireworks-tech-graph` | Override fireworks install location. Default matches `npx skills add -g` and where opencode loads sibling skills from; Claude Code users typically set this to `~/.claude/skills/fireworks-tech-graph` |

## Layout

```
plugins/diagramming/
├── README.md             # this file
├── Justfile              # bootstrap recipe (imported by root Justfile)
├── openpackage.yml       # marketplace manifest (auto-generated)
├── package.json          # pptxgenjs declaration
├── agents/
│   └── diagramming-engineer.md
├── skills/
│   ├── architecture-diagrams/SKILL.md
│   └── flow-diagrams/SKILL.md
├── scripts/
│   ├── build-drawio.py       # JSON to .drawio XML
│   ├── build-deck.js         # deck-spec.json to .pptx (PptxGenJS)
│   └── validate-diagram.py   # .drawio to WCAG AA contrast check
├── evals/
│   ├── run-cases.ts          # 7 rendering cases + PowerPoint smoke
│   ├── run-routing-eval.ts   # static routing fixture validator
│   └── routing-fixtures.jsonl
└── docs/
    ├── diagrams/             # 5 PR hero diagrams
    └── decks/                # 1 sample 5-slide deck
```

## Reuse

This plugin deliberately delegates rather than reimplements:

- Renders via `fireworks-tech-graph` (sibling skill from yizhiyanhua-ai)
- Deck assembly via `PptxGenJS` (path Anthropic's `pptx` skill recommends)
- Visual audit via `ui-visual-validator` (in `plugins/accessibility-compliance/`)
- C4 synthesis via `c4-context` / `c4-container` / `c4-component` / `c4-code` (in `plugins/c4-architecture/`)
- Raw Mermaid via `mermaid-expert` (in `.opencode/agents/`)

`diagramming-engineer` is a thin router. The only new code is the drawio builder, the WCAG validator, and the PptxGenJS wrapper.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `ERROR: pptxgenjs not installed` | `cd plugins/diagramming && npm install` (or `just diagramming-bootstrap`) |
| `ERROR: rsvg-convert not found` | `brew install librsvg` / `apt-get install librsvg2-bin` |
| `ERROR: fireworks-tech-graph not found at ~/.agents/skills/...` | `npx skills add yizhiyanhua-ai/fireworks-tech-graph --force -g -y` (the `-g` flag is required) or set `FIREWORKS_TECH_GRAPH_HOME` if your install lives elsewhere (e.g. `~/.claude/skills/fireworks-tech-graph`) |
| `WCAG contrast check failed` on your own `.drawio` | A `style_overrides` put dark text on dark fill or vice versa. Run `python3 plugins/diagramming/scripts/validate-diagram.py your.drawio` to see which cell, then fix the colors. |
| drawio CLI emits a Windows / Wine error on macOS | The Electron CLI sometimes ships a stale entrypoint. `brew reinstall --cask drawio` usually fixes it. |
| `.pptx` opens with blank slides in Keynote | Open in PowerPoint or LibreOffice once first; Keynote occasionally reflows on import. |

## Related ADRs

- RIC-353 - diagramming agent (parent)
- RIC-354 - architecture-diagrams skill
- RIC-355 - flow-diagrams skill
- RIC-401 - Katalyst three-loop process (appendix diagrams live outside this RIC-353 PR)
