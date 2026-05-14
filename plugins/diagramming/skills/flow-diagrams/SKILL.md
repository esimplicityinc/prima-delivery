---
name: flow-diagrams
description: Generate flow diagrams (sequence diagrams, flowcharts, ERDs, state machines) from API route definitions, database schemas, code paths, or prose descriptions. Two renderers — fireworks-tech-graph (SVG + PNG, default, clean topology) and draw.io (.drawio XML + PNG, best for dense flowcharts with named feedback loops). Optionally assembles diagrams into a PowerPoint deck via PptxGenJS (Anthropic-skill-recommended) in powerpoint mode. Use for code-derived flow visualizations; use architecture-diagrams for system architecture, deployment, network topology.
version: 1.4.0
---

# flow-diagrams

Generate sequence diagrams, flowcharts, ERDs, and state machines as SVG (with PNG export) by translating source material (API routes, database schemas, code, prose) into structured input for the `fireworks-tech-graph` skill, then validating the output with `rsvg-convert`.

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

- `rsvg-convert` — install: `brew install librsvg` (macOS) or `apt-get install librsvg2-bin` (Linux/Debian)
- `fireworks-tech-graph` skill — install: `npx skills add yizhiyanhua-ai/fireworks-tech-graph`
- `python3` (used by fireworks-tech-graph's helpers)
- `pptxgenjs` (only for `mode: powerpoint`) — `cd plugins/diagramming && npm install`

Check at startup; fail loudly with the platform-specific install hint if missing.

## Renderer choice (v1.2.0)

This skill supports two renderers; the user picks via `renderer` field in the input contract or the `DIAGRAM_DEFAULT_RENDERER` env var. The skill itself can also pick a default based on diagram type.

| Renderer | Output | When to use |
|----------|--------|-------------|
| `fireworks` (default) | SVG + PNG via fireworks-tech-graph | Sequence, ERD, simple flowchart, state machine. Clean topology, fast, validated by rsvg-convert |
| `drawio` | `.drawio` XML + PNG via draw.io desktop CLI | Dense flowcharts with **named feedback loops** (3+ backloops), process diagrams that need explicit waypoint routing, anything where fireworks-tech-graph's auto-layout produces label collisions |

**Rule of thumb for this skill:** if the user's request mentions "iterative", "feedback loops", "named loops", "backloops", or describes more than 3 cross-stage feedback paths → default to `drawio`. Otherwise default to `fireworks`. The user's explicit `renderer` field always wins.

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

Phase 1 — Analyze input

For each diagram, read the source files and extract:

- **sequence**: participants (caller, server, downstream services), messages between them, ordering, error paths, async vs sync calls
- **flowchart**: start, end, decision points (with conditions), processes, I/O steps
- **erd**: entities (tables/types), attributes (columns, with primary key + foreign key markers), relationships (with cardinality: 1, N, 0..1, 0..*, 1..*)
- **state-machine**: states, transitions (with event/guard/action labels), initial state, final state(s), composite states if any

Do not infer. Read the actual source.

Phase 2 — Translate to fireworks-tech-graph input

fireworks-tech-graph's renderer is **input-shape-uniform**: every template type consumes the same `{ title, subtitle, viewBox, nodes[], arrows[], containers[]?, legend[]? }` shape. The template-type argument only sets the default viewBox size; it does not unlock template-specific fields like `participants` or `entities`. The diagram type lives in how you compose `nodes` and `arrows`.

Composition by diagram type (essential reading — getting this wrong yields a title-only blank canvas):

- **sequence** → render lifelines as nodes laid out horizontally at a single small `y` (e.g., `y: 130`), one per participant. Render messages as arrows between those nodes. fireworks-tech-graph routes the arrows; the visual lifelines form naturally from the participants' x positions. Approximate viewBox: `"0 0 960 700"` for ≤ 8 messages, taller for more.
- **flowchart** → nodes at process steps, snapped to a 120px×80px grid (top-to-bottom flow). Use `kind: "process"` for actions and `kind: "decision"` for diamonds. Arrows carry the branch labels (`yes`, `no`, condition strings).
- **erd** → entity rects as nodes. Put the entity's attributes inside the node's `label` using newlines (`\n`). Mark PK with `(PK)`, FK with `(FK)`. Render relationships as arrows between entities; put cardinality + role in the arrow `label` (e.g., `"1..N has"`).
- **state-machine** → states as nodes (`kind: "process"`). Initial and final states as small visual circles drawn via additional small nodes. Transitions as arrows with `event [guard] / action` in the label.

Phase 3 — Generate (renderer-dependent)

### When `renderer == "fireworks"` (default)

```bash
python3 ~/.claude/skills/fireworks-tech-graph/scripts/generate-from-template.py \
  <template-type> \
  "$OUTPUT_DIR/<slug>.svg" \
  '<json>'
```

Template type mapping (user-facing → fireworks-tech-graph): `sequence` → `sequence`, `flowchart` → `flowchart`, `erd` → `er-diagram`, `state-machine` → `state-machine`. Honor `FIREWORKS_TECH_GRAPH_HOME` env var for the install path.

If a diagram requires layout beyond `nodes` + `arrows`, fall back to authoring raw SVG via fireworks-tech-graph's Python list method.

### When `renderer == "drawio"`

The `.drawio` builder takes a slightly richer JSON than fireworks-tech-graph: each node may include `kind` (`process` | `decision` | `data` | `terminator`) and optional `style_overrides`; each arrow may include `kind` (`control` | `feedback` | `data`), `exit_port` / `entry_port` (`T` | `B` | `L` | `R`), and explicit `waypoints[]` for routing. This control is what makes draw.io land cleanly on dense feedback graphs.

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

Phase 4 — Validate + export

When `renderer == "fireworks"`:

```bash
# Either path validates and exports. /dev/null may be rejected on some
# rsvg-convert versions; the PNG export below doubles as validation.
rsvg-convert -w 1920 "$OUTPUT_DIR/<slug>.svg" -o "$OUTPUT_DIR/<slug>.png"
```

When `renderer == "drawio"`:

The drawio CLI's PNG export step IS the validation; non-zero exit means the .drawio is malformed. If the CLI isn't installed, validate by parsing the XML with any standard XML parser (well-formedness check).

Failure recovery as documented in `architecture-diagrams` (max three retries; switch generation method on second failure; report and stop on third).

Phase 5 — PowerPoint mode (when `mode == "powerpoint"`)

Identical to `architecture-diagrams`. After all SVG + PNGs are rendered, build a `deck-spec.json` and shell out to:

```bash
node plugins/diagramming/scripts/build-deck.js <deck-spec.json> "$OUTPUT_DIR/<deck-slug>.pptx"
```

Uses [PptxGenJS](https://gitbrent.github.io/PptxGenJS/) — the path Anthropic's `pptx` skill recommends. Run `npm install` once in `plugins/diagramming/` before first use.

In a mixed-skill request (this skill + `architecture-diagrams` for the same deck), the `diagramming-engineer` agent coordinates which skill writes the `.pptx`. See `diagramming-engineer.md` for the cross-skill protocol; both skills read/write a `$OUTPUT_DIR/.deck-manifest.json` so the final invocation builds a single deck with all slides.

Phase 6 — Visual validation (always run for drawio; optional for fireworks)

Government-agency reference architecture has accessibility constraints. Every diagram should clear WCAG AA contrast (4.5:1 for body text, 3:1 for large) so that color-only encoding doesn't lock anyone out. Two layers of validation:

### Layer A — fast deterministic contrast check (always)

```bash
python3 <plugin-root>/plugins/diagramming/scripts/validate-diagram.py \
  "$OUTPUT_DIR/<slug>.drawio"
```

Parses the .drawio XML, walks every vertex cell, computes WCAG 2.x contrast ratio between `fontColor` and `fillColor`. Exits 0 on pass, 1 on fail. Default threshold is AA (4.5); pass `--threshold 7.0` for AAA. JSON output via `--json`.

For `fireworks` renderer: this script accepts only .drawio input. To check fireworks-rendered SVGs you can either skip layer A (the built-in palette already clears AA) or convert to .drawio for the audit. v1.4.0 adds layer A to the drawio path; SVG contrast checking is a follow-up.

### Layer B — full visual audit via the ui-visual-validator agent (optional)

For richer validation (typography readability at the chosen scale, layout overlap, focus-indicator-equivalents in static diagrams, color-blind safety beyond contrast), dispatch the `ui-visual-validator` agent (in `plugins/accessibility-compliance/agents/ui-visual-validator.md`) against the rendered PNG. The agent does pixel-level analysis grounded in WCAG 2.2 and reports specific findings.

Invoke when the user asks for accessibility audit, when the diagram is going into a customer-facing artifact (deck, doc, report), or when layer A passes but the diagram still looks crowded. Skip otherwise — layer A catches the high-frequency failure mode (bad contrast) at near-zero cost.

The agent expects a screenshot path. Pass it `<output_dir>/<slug>.png` and the prompt "Audit this diagram for WCAG 2.2 AA compliance — focus on color contrast, text readability at typical zoom, layout density, and color-blind safety. List specific findings with cell-level coordinates if possible."

Phase 7 — Diff-update path (when `diff` is present)

For sequence and flow diagrams, the diff usually maps to "added/removed messages" or "added/removed states." Re-extract from the changed source regions and merge into the prior structure. For ERDs, the diff usually adds/removes columns or relationships.

Validate as in Phase 4 and Phase 6. Report a diff summary alongside the updated diagram.

## Output

For each diagram:

- `<output_dir>/<slug>.svg`
- `<output_dir>/<slug>.png` (1920px wide)
- Short prose description

`<slug>` derived from `diagram.title` (lowercase, hyphenate, collapse repeats).

## Constraints

- Never invent participants, messages, columns, states, or transitions. Each must trace to a specific line in the source files or an explicit user statement.
- Never deliver an SVG without `rsvg-convert` validation passing.
- Default to fireworks-tech-graph style 1 (Flat Icon). Override via input or `DIAGRAM_DEFAULT_STYLE`.
- For sequence diagrams with more than ~12 messages, split into multiple diagrams (one per logical phase) instead of a single tall canvas.
- For ERDs with more than ~8 entities, split into related-entity clusters.

## Coexistence with other agents

- The `mermaid-expert` agent (in `.opencode/agents/`) produces raw Mermaid source for downstream consumers that need Mermaid output specifically. It is complementary, not a fallback for this skill.
