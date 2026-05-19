---
name: flow-diagrams
description: Coordinate the rendering of sequence diagrams, flowcharts, ERDs, and state machines. Reads source material (API routes, database schemas, code, prose), routes each diagram to the chosen renderer (fireworks-tech-graph for SVG, drawio for .drawio XML + PNG), and assembles results into a deck when mode is powerpoint. Composition is delegated - fireworks composes via its own SKILL.md vocabulary; drawio via this plugin's build-drawio.py contract. Use for code-derived flow visualizations; use architecture-diagrams for system architecture, deployment, network topology.
version: 2.1.0
---

# flow-diagrams

Coordinate the rendering of sequence diagrams, flowcharts, ERDs, and state machines. This skill reads source material (API routes, database schemas, code, prose), routes each diagram to the chosen renderer (`fireworks-tech-graph` for SVG, drawio for `.drawio` XML + PNG), and assembles the results into a deck when `mode: powerpoint`. Composition itself is delegated - fireworks composes via its own SKILL.md vocabulary; drawio composes via this plugin's `build-drawio.py` contract.

## When to use this skill

Use this skill when the user asks for any of:

- A sequence diagram from API routes, code execution flow, or a described interaction
- A flowchart / process flow from code or a described workflow
- An entity-relationship diagram (ERD) from a database schema (Drizzle, Prisma, SQL, plain ORM definitions)
- A state machine diagram from an enum-driven flow, an XState chart, or described state transitions
- A data-flow diagram for a pipeline (ETL, ingestion, transformation chain)

For system architecture, deployment topology, network diagrams, or infrastructure, use the sibling `architecture-diagrams` skill instead.

## Prerequisites

Run `just diagramming-bootstrap` from the repo root once per machine. It installs every dep (rsvg-convert, node, fireworks-tech-graph skill, pptxgenjs) and verifies each one. Idempotent.

Manual fallback (if `just` isn't available):

- `rsvg-convert` - install: `brew install librsvg` (macOS) or `apt-get install librsvg2-bin` (Linux/Debian)
- `fireworks-tech-graph` skill - install: `npx skills add yizhiyanhua-ai/fireworks-tech-graph`
- `python3` (used by fireworks-tech-graph's helpers)
- `pptxgenjs` (only for `mode: powerpoint`) - `cd plugins/diagramming && npm install`

Check at startup; fail loudly with the platform-specific install hint if missing.

## Renderer choice (v2.1.0)

This skill supports two renderers; the user picks via `renderer` field in the input contract or the `DIAGRAM_DEFAULT_RENDERER` env var. The skill itself can also pick a default based on diagram type.

| Renderer | Output | When to use |
|----------|--------|-------------|
| `fireworks` (default) | SVG + PNG via fireworks-tech-graph | Sequence, ERD, simple flowchart, state machine. Clean topology, fast, validated by rsvg-convert |
| `drawio` | `.drawio` XML + PNG via draw.io desktop CLI | Dense flowcharts with **named feedback loops** (3+ backloops), process diagrams that need explicit waypoint routing, anything where fireworks-tech-graph's auto-layout produces label collisions |

**Rule of thumb for this skill:** if the user's request mentions "iterative", "feedback loops", "named loops", "backloops", or describes more than 3 cross-stage feedback paths → default to `drawio`. Otherwise default to `fireworks`. The user's explicit `renderer` field always wins.

If a first render is visually ugly, do not hand-edit the SVG or PNG. Classify the graph and rerender with the renderer that fits that class. Label collisions, loops crossing node interiors, dense backloops, or arrows stacked on the same corridor are drawio signals. Simple linear flows, short sequence diagrams, and compact ERDs stay with fireworks.

## Input contract

```jsonc
{
  "mode": "plain",                         // "plain" | "powerpoint" (since v1.1.0)
  "renderer": "fireworks",                  // "fireworks" | "drawio" (since v1.2.0); default per the rule above; env: DIAGRAM_DEFAULT_RENDERER
  "output_dir": "./diagrams/",             // override with env: DIAGRAM_OUTPUT_DIR
  "style": 1,                               // 1-7 fireworks-tech-graph style (ignored when renderer == "drawio"); override with env: DIAGRAM_DEFAULT_STYLE

  "deck": {                                 // present only when mode == "powerpoint"
    "title": "...",                         // required in powerpoint mode; can be set via env: DIAGRAM_DECK_TITLE
    "theme": "default",
    "author": "..."
  },

  "diagrams": [
    {
      "type": "sequence",                   // also: "flowchart", "erd", "state-machine" (translated to fireworks-tech-graph template names internally: erd -> er-diagram)
      "title": "Login request flow",
      "description": "User submits credentials, API validates, returns JWT.",
      "source": {
        // Type-specific. Examples:
        // For "sequence": { "routes": ["./api/src/routes/auth.ts"] }
        // For "flowchart": { "code": ["./api/src/services/payment.ts"] }
        // For "erd": { "schema": "./db/schema.ts" }
        // For "state-machine": { "enum": "./src/order-state.ts" }
      },
      "diff": null                           // optional unified-diff string; when present, update the existing diagram rather than re-render from scratch
    }
  ]
}
```

Environment variables override input fields when set.

## Workflow

This skill is a **coordinator**, not a translator. Its job is to read source material, dispatch each diagram to the right renderer, and (when `mode: powerpoint`) accumulate renders into one deck. The actual diagram composition is delegated to the renderer's own skill - we deliberately do not constrain the LLM to a structured JSON shape, because that produced narrower output than the renderer can natively support.

Phase 1 - Analyze input

For each diagram, read the source files and extract:

- **sequence**: participants (caller, server, downstream services), messages between them, ordering, error paths, async vs sync calls
- **flowchart**: start, end, decision points (with conditions), processes, I/O steps
- **erd**: entities (tables/types), attributes (columns, with primary key + foreign key markers), relationships (with cardinality: 1, N, 0..1, 0..*, 1..*)
- **state-machine**: states, transitions (with event/guard/action labels), initial state, final state(s), composite states if any

Do not infer. Read the actual source.

Phase 2 - Compose + render

The composition pattern depends on the renderer.

### When `renderer == "fireworks"` (default)

**Delegate to `fireworks-tech-graph`'s SKILL.md** for composition. Load it from `~/.agents/skills/fireworks-tech-graph/SKILL.md` (or the path set by `FIREWORKS_TECH_GRAPH_HOME` - Claude Code installs typically use `~/.claude/skills/fireworks-tech-graph/SKILL.md` instead) and follow its workflow verbatim - Diagram Types & Layout Rules (which include sequence, flowchart, ERD, state machine, and timeline), Shape Vocabulary, Arrow Semantics, Layout Rules & Validation, Styles 1-7, and the SVG generation strategy. fireworks teaches its own complete vocabulary; this skill does not duplicate or constrain it.

The render produces an SVG at a path of your choosing; honor `DIAGRAM_OUTPUT_DIR` if set, otherwise default to the current working directory. fireworks's workflow includes its own validation step (`rsvg-convert ... -o /dev/null`) and PNG export (`rsvg-convert -w 1920 ...`). Do not skip these - they are part of the renderer's contract, not optional.

If you find yourself wanting to invoke `generate-from-template.py` with a structured `{ nodes[], arrows[], containers[] }` JSON, stop. That is a legacy path that produces narrower output than fireworks's free-form SVG composition. Use the SVG-authoring path fireworks's SKILL.md describes ("MANDATORY: Python List Method" or direct SVG composition).

### When `renderer == "drawio"`

The `.drawio` builder takes JSON of shape `{ title, subtitle?, nodes[], arrows[], containers[]?, legend[]? }`: each node may include `kind` (`process` | `decision` | `data` | `terminator`) and optional `style_overrides`; each arrow may include `kind` (`control` | `feedback` | `data`), `exit_port` / `entry_port` (`T` | `B` | `L` | `R`), and explicit `waypoints[]` for routing. This control is what makes draw.io land cleanly on dense feedback graphs.

Compose your JSON to match this shape, then:

```bash
# Path to the helper that ships with this plugin. Discoverable via the plugin
# directory; in development, find it at:
#   <prima-delivery-root>/plugins/diagramming/scripts/build-drawio.py
python3 <plugin-root>/plugins/diagramming/scripts/build-drawio.py \
  <input.json> \
  "$OUTPUT_DIR/<slug>.drawio"
```

Then export PNG via the drawio CLI (`brew install --cask drawio` provides it):

```bash
drawio --export --format png --scale 2 \
  --output "$OUTPUT_DIR/<slug>.png" \
  "$OUTPUT_DIR/<slug>.drawio"
```

If `drawio` CLI is not available, deliver the `.drawio` file alone and tell the user to open it in diagrams.net web (drag-drop) or any drawio editor.

**Composition advice for drawio:**

- Use `exit_port: "L"` + `entry_port: "L"` for feedback arrows that curve out the LEFT side of the source and re-enter the LEFT side of the target. Same with `"R"` + `"R"` for the right corridor.
- For nested arcs (multiple feedback arrows in the same corridor), prefer the `lane` field over hand-computed `waypoints[]`. `lane: 1` is the closest lane to the spine; lane N sits N-1 lane widths farther out. Lane 1 corridor x ≈ source.x − 60; each additional lane adds 50px. The `build-drawio.py` helper computes the exact waypoints from source/target geometry, so wider nodes automatically push the corridor further out without you doing the math. Explicit `waypoints[]` always wins when both are provided.
- Decision shapes (rhombus): `kind: "decision"`. Width usually +20-40px wider than process boxes to fit the same label.
- Use `kind: "data"` for any annotation or callout box (loop labels, skip-discipline notes, artifact stores).
- `style_overrides` lets you tweak fillColor / strokeColor / fontSize per node (full mxGraph style syntax). Use sparingly.

Phase 3 - Validate

For both renderers, validation is part of Phase 2's render step (fireworks: `rsvg-convert`; drawio: `drawio --export` exits non-zero on malformed XML). After Phase 2 completes, the file on disk is already validated. This phase exists for failure recovery semantics.

If the render fails, do not retry the same composition. Apply a targeted fix (or switch composition strategies - for fireworks, that's switching from templated to direct SVG authoring; for drawio, fixing the JSON shape). After three failures on a single diagram, stop and report the error to the user with file/line context.

Phase 4 - PowerPoint mode (when `mode == "powerpoint"`)

Identical to `architecture-diagrams`. After all diagrams have been rendered (Phases 1-3 complete for each), build a `deck-spec.json` and shell out to:

```bash
node plugins/diagramming/scripts/build-deck.js <deck-spec.json> "$OUTPUT_DIR/<deck-slug>.pptx"
```

Uses [PptxGenJS](https://gitbrent.github.io/PptxGenJS/) - the path Anthropic's `pptx` skill recommends. Run `npm install` once in `plugins/diagramming/` before first use.

In a mixed-skill request (this skill + `architecture-diagrams` for the same deck), the `diagramming-engineer` agent coordinates which skill writes the `.pptx`. See `diagramming-engineer.md` for the cross-skill protocol; both skills read/write a `$OUTPUT_DIR/.deck-manifest.json` so the final invocation builds a single deck with all slides.

Phase 5 - Visual validation (always run for drawio; optional for fireworks)

Government-agency reference architecture has accessibility constraints. Every diagram should clear WCAG AA contrast (4.5:1 for body text, 3:1 for large) so that color-only encoding doesn't lock anyone out. Two layers of validation:

### Layer A - fast deterministic contrast check (always)

```bash
python3 <plugin-root>/plugins/diagramming/scripts/validate-diagram.py \
  "$OUTPUT_DIR/<slug>.drawio"
```

Parses the .drawio XML, walks every vertex cell, computes WCAG 2.x contrast ratio between `fontColor` and `fillColor`. Exits 0 on pass, 1 on fail. Default threshold is AA (4.5); pass `--threshold 7.0` for AAA. JSON output via `--json`.

For `fireworks` renderer: this script currently accepts only .drawio input. To check fireworks-rendered SVGs you can either skip layer A (fireworks's documented styles 1-7 already clear AA) or convert to .drawio for the audit.

### Layer B - full visual audit via the ui-visual-validator agent (optional)

For richer validation (typography readability at the chosen scale, layout overlap, focus-indicator-equivalents in static diagrams, color-blind safety beyond contrast), dispatch the `ui-visual-validator` agent (in `plugins/accessibility-compliance/agents/ui-visual-validator.md`) against the rendered PNG. The agent does pixel-level analysis grounded in WCAG 2.2 and reports specific findings.

Invoke when the user asks for accessibility audit, when the diagram is going into a customer-facing artifact (deck, doc, report), or when layer A passes but the diagram still looks crowded. Skip otherwise - layer A catches the high-frequency failure mode (bad contrast) at near-zero cost.

The agent expects a screenshot path. Pass it `<output_dir>/<slug>.png` and the prompt "Audit this diagram for WCAG 2.2 AA compliance - focus on color contrast, text readability at typical zoom, layout density, and color-blind safety. List specific findings with cell-level coordinates if possible."

Phase 6 - Diff-update path (when `diff` is present)

For sequence and flow diagrams, the diff usually maps to "added/removed messages" or "added/removed states." Re-extract from the changed source regions and merge into the prior structure. For ERDs, the diff usually adds/removes columns or relationships.

Validate as in Phase 3 and Phase 5. Report a diff summary alongside the updated diagram.

## Output

For each diagram:

- `<output_dir>/<slug>.svg`
- `<output_dir>/<slug>.png` (1920px wide)
- Short prose description

`<slug>` derived from `diagram.title` (lowercase, hyphenate, collapse repeats).

## Constraints

- Never invent participants, messages, columns, states, or transitions. Each must trace to a specific line in the source files or an explicit user statement.
- Never deliver an SVG without `rsvg-convert` validation passing (fireworks renderer); never deliver a `.drawio` without the drawio CLI export passing or, if CLI absent, well-formed XML (drawio renderer).
- For fireworks: follow `fireworks-tech-graph`'s SKILL.md verbatim - its Diagram Types, Shape Vocabulary, Arrow Semantics, Layout Rules, and Styles 1-7. Do not constrain its composition to a structured `{ nodes[], arrows[] }` JSON shape; that produces narrower output than the renderer can natively support.
- Do not hardcode project names, paths, or credentials in any output. Read from input or env (`DIAGRAM_OUTPUT_DIR`, `FIREWORKS_TECH_GRAPH_HOME`, `DIAGRAM_DEFAULT_RENDERER`, `DIAGRAM_DEFAULT_STYLE`, `DIAGRAM_DECK_TITLE`).
- For sequence diagrams with more than ~12 messages, split into multiple diagrams (one per logical phase) instead of a single tall canvas.
- For ERDs with more than ~8 entities, split into related-entity clusters.

## Coexistence with other agents

- The `mermaid-expert` agent (in `.opencode/agents/`) produces raw Mermaid source for downstream consumers that need Mermaid output specifically. It is complementary, not a fallback for this skill.
