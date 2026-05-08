---
name: flow-diagrams
description: Generate SVG + PNG flow diagrams (sequence diagrams, flowcharts, ERDs, state machines) from API route definitions, database schemas, code paths, or prose descriptions. Renders via the fireworks-tech-graph skill, validated by rsvg-convert. Use for code-derived flow visualizations; use architecture-diagrams for system architecture, deployment, network topology.
version: 1.0.0
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

Same as `architecture-diagrams`:

- `rsvg-convert` — install: `brew install librsvg` (macOS) or `apt-get install librsvg2-bin` (Linux/Debian)
- `fireworks-tech-graph` skill — install: `npx skills add yizhiyanhua-ai/fireworks-tech-graph`
- `python3` (used by fireworks-tech-graph's helpers)

Check at startup; fail loudly with the platform-specific install hint if missing.

## Input contract

```jsonc
{
  "mode": "plain",                         // v1.0.0 ships plain only; "powerpoint" lands in a follow-up
  "output_dir": "./diagrams/",             // override with env: DIAGRAM_OUTPUT_DIR
  "style": 1,                               // 1-7 fireworks-tech-graph style; override with env: DIAGRAM_DEFAULT_STYLE

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

Phase 3 — Generate

```bash
python3 ~/.claude/skills/fireworks-tech-graph/scripts/generate-from-template.py \
  <template-type> \
  "$OUTPUT_DIR/<slug>.svg" \
  '<json>'
```

Template type mapping (user-facing → fireworks-tech-graph): `sequence` → `sequence`, `flowchart` → `flowchart`, `erd` → `er-diagram`, `state-machine` → `state-machine`. Honor `FIREWORKS_TECH_GRAPH_HOME` env var for the install path.

If a diagram requires layout beyond `nodes` + `arrows`, fall back to authoring raw SVG via fireworks-tech-graph's Python list method.

Phase 4 — Validate + export

```bash
rsvg-convert "$OUTPUT_DIR/<slug>.svg" -o /dev/null && echo OK
rsvg-convert -w 1920 "$OUTPUT_DIR/<slug>.svg" -o "$OUTPUT_DIR/<slug>.png"
```

Failure recovery as documented in `architecture-diagrams` (max three retries; switch generation method on second failure; report and stop on third).

Phase 5 — Diff-update path (when `diff` is present)

For sequence and flow diagrams, the diff usually maps to "added/removed messages" or "added/removed states." Re-extract from the changed source regions and merge into the prior structure. For ERDs, the diff usually adds/removes columns or relationships.

Validate as in Phase 4. Report a diff summary alongside the updated SVG.

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
