---
name: architecture-diagrams
description: Coordinate the rendering of architecture, deployment, network, and infrastructure diagrams. Reads source material (k8s manifests, Terraform, ADRs, prose), routes each diagram to the chosen renderer (fireworks-tech-graph for SVG, drawio for .drawio XML + PNG), and assembles results into a deck when mode is powerpoint. Composition is delegated - fireworks composes via its own SKILL.md vocabulary; drawio via this plugin's build-drawio.py contract. Use for system architecture, deployment, network topology; use flow-diagrams for sequence, ERD, state, flowchart.
version: 2.2.0
---

# architecture-diagrams

Coordinate the rendering of architecture, deployment, infrastructure, and network topology diagrams. This skill reads source material (k8s manifests, Terraform, ADRs, prose), routes each diagram to the chosen renderer (`fireworks-tech-graph` for SVG, drawio for `.drawio` XML + PNG), and assembles the results into a deck when `mode: powerpoint`. Composition itself is delegated - fireworks composes via its own SKILL.md vocabulary; drawio composes via this plugin's `build-drawio.py` contract.

## When to use this skill

Use this skill when the user asks for any of:

- A system architecture diagram (services + connections + data stores)
- A deployment topology (containers, pods, nodes, regions)
- An infrastructure diagram (VPCs, subnets, load balancers, cloud resources)
- A network topology (firewalls, routers, zones, traffic flow)
- A C4 context, container, or component diagram (visual representation; use the `c4-*` agents in `c4-architecture` for code-level synthesis first if needed)

For sequence diagrams, ERDs, state machines, flowcharts, or process flows, use the sibling `flow-diagrams` skill instead.

## Prerequisites

Run `just diagramming-bootstrap` from the repo root once per machine. It installs every dep (rsvg-convert, node, fireworks-tech-graph skill, pptxgenjs) and verifies each one. Idempotent - safe to re-run.

Manual fallback (if `just` isn't available):

- `rsvg-convert` - install: `brew install librsvg` (macOS) or `apt-get install librsvg2-bin` (Linux/Debian)
- `fireworks-tech-graph` skill - install: `npx skills add yizhiyanhua-ai/fireworks-tech-graph`
- `pptxgenjs` (only for `mode: powerpoint`) - `cd plugins/diagramming && npm install`

`python3` is also required (used by fireworks-tech-graph's helpers). Standard on most systems.

## Renderer choice (v2.2.0)

| Renderer | Output | When to use |
|----------|--------|-------------|
| `fireworks` | SVG + PNG via fireworks-tech-graph | Simple C4 context/container diagrams, simple deployment topology, simple network diagrams with few labels and little cross-tier routing |
| `drawio` | `.drawio` XML + PNG via draw.io desktop CLI | Dense deployment diagrams, CI/CD plus runtime diagrams, hub-and-spoke topology, many labeled cross-tier paths, auth or token flows crossing operational lanes |

**Renderer selection order:**

1. Honor an explicit `renderer` in input.
2. Honor `DIAGRAM_DEFAULT_RENDERER` when set.
3. Default to `drawio` when the graph class is dense: four or more operational lanes, eight or more nodes, eight or more arrows, multiple long cross-tier arrows, or a mix of CI/CD, auth/OIDC, runtime, user, and post-deploy verification concerns in one diagram.
4. Default to `fireworks` for simple architecture diagrams that fit in one clean top-to-bottom or left-to-right flow.

If a first render is visually ugly, do not hand-edit the SVG or PNG. Classify why it is ugly, switch renderer by graph class, then rerender through the skill. Examples: clipped node titles, arrow labels drawn over node titles, legend collisions, lane labels under arrows, and token or request labels overlapping component edges all mean this is a drawio class of architecture graph.

The full drawio invocation pattern is documented in `flow-diagrams/SKILL.md` (Phase 3, "When `renderer == drawio`"); this skill follows the same protocol.

## Input contract

```jsonc
{
  "mode": "plain",                         // "plain" | "powerpoint" (since v1.1.0)
  "renderer": "fireworks",                  // "fireworks" | "drawio" (since v1.2.0); env: DIAGRAM_DEFAULT_RENDERER
  "output_dir": "./diagrams/",             // override with env: DIAGRAM_OUTPUT_DIR
  "output": {                                // since v2.2.0; env: DIAGRAM_OUTPUT_FORMATS
    "formats": ["svg", "png"]               // fireworks: "svg" | "png"; drawio: "drawio" | "png" | "svg"
  },
  "style": 1,                               // 1-7 fireworks-tech-graph style (ignored when renderer == "drawio"); override with env: DIAGRAM_DEFAULT_STYLE

  "deck": {                                 // present only when mode == "powerpoint"
    "title": "...",                         // required in powerpoint mode; can be set via env: DIAGRAM_DECK_TITLE
    "theme": "default",
    "author": "..."
  },

  "diagrams": [
    {
      "type": "architecture",               // also: "network-topology", "deployment"
      "title": "Frontend services topology",
      "description": "Two-tier deployment: Astro frontend serving SSR pages, Elysia API backing it.",
      "source": {
        // Type-specific. Examples:
        // For "architecture": { "manifests": ["./infra/k8s/*.yaml"], "adrs": ["./docs/adr-016.md"] }
        // For "network-topology": { "topology": { "zones": [...], "devices": [...] } }
        // For "deployment": { "manifests": ["./infra/k8s/deployment.yaml"] }
      },
      "diff": null                           // optional unified-diff string; when present, update the existing diagram rather than re-render from scratch
    }
  ]
}
```

Environment variables override input fields when set. Required env vars fail loudly if missing in the contexts where they apply (`DIAGRAM_DECK_TITLE` is required only in powerpoint mode, which lands in a follow-up). `DIAGRAM_OUTPUT_FORMATS` is a comma-separated list such as `svg,png`, `png`, `svg`, or `drawio,png`.

### Output format selection

Default behavior remains `output.formats: ["svg", "png"]` for `mode: plain` because most documentation workflows need editable source plus a shareable preview. The user may narrow the delivered artifacts either with structured input or natural language:

- "PNG only", "just give me the PNG", "screenshot only" -> `output.formats: ["png"]`
- "SVG only", "source only", "editable only" -> `output.formats: ["svg"]` for fireworks or `output.formats: ["drawio"]` for drawio
- "drawio and PNG" -> `output.formats: ["drawio", "png"]`
- "both", "docs/PR ready", or no explicit format request -> renderer default pair (`["svg", "png"]` for fireworks, `["drawio", "png"]` for drawio)

Validation is not optional. A PNG-only fireworks request may still create a temporary SVG so XML validation and raster export can run. A PNG-only drawio request may still create temporary `.drawio` XML so drawio export can run. Report and preserve only the requested final formats when feasible.

## Default design template

Unless the user supplies a specific visual system, apply this restrained developer-documentation template:

### Palette

Use no more than four semantic colors in one diagram:

- Specs / inputs: muted teal stroke + very light teal fill.
- Processes / actions: indigo stroke + very light indigo fill.
- Generated artifacts: cyan stroke + hatch/stripe pattern or `GENERATED` badge.
- Validation / success gates: green stroke + very light green fill.

Use neutral gray dashed boxes for references and dependencies. Do not introduce extra category colors unless the diagram needs a richer legend and the user explicitly accepts that tradeoff.

### Layout

- Prefer a single dominant spine or clear swimlanes.
- Put parallel work in a grouped panel rather than floating it off-grid.
- Use one input bus when multiple artifacts feed the same node.
- Avoid crossing feeder lines over process boxes.
- Place legends below the diagram with enough margin so they never cover nodes.

### Typography and borders

- Use consistent title, node-title, subtitle, and label sizes across a diagram.
- Use dark text on light fills. Do not use white text on pale fills.
- Use rounded rectangles for normal steps.
- Use dashed rounded rectangles for references/dependencies.
- Use diamonds only for decision points.
- Use hatching or a `GENERATED` badge to distinguish generated artifacts; do not rely on color alone.

## Workflow

This skill is a **coordinator**, not a translator. Its job is to read source material, dispatch each diagram to the right renderer, and (when `mode: powerpoint`) accumulate renders into one deck. The actual diagram composition is delegated to the renderer's own skill - we deliberately do not constrain the LLM to a structured JSON shape, because that produced narrower output than the renderer can natively support.

Phase 1 - Analyze input

1. Read source material listed under each diagram's `source` block. Do not infer structure; read the actual files.
2. For each diagram, extract:
   - Nodes (services, components, devices, resources)
   - Edges (connections, data flow, deployment relationships)
   - Layers / groups (zones, tiers, regions, namespaces)
   - Labels (names, types, ports, IPs as relevant to the diagram type)

Phase 2 - Compose + render

The composition pattern depends on the renderer.

### When `renderer == "fireworks"` (default)

**Delegate to `fireworks-tech-graph`'s SKILL.md** for composition. Load it from `~/.agents/skills/fireworks-tech-graph/SKILL.md` (or the path set by `FIREWORKS_TECH_GRAPH_HOME` - Claude Code installs typically use `~/.claude/skills/fireworks-tech-graph/SKILL.md` instead) and follow its workflow verbatim - Diagram Types & Layout Rules, Shape Vocabulary, Arrow Semantics, Layout Rules & Validation, Styles 1-7, and the SVG generation strategy. fireworks teaches its own complete vocabulary; this skill does not duplicate or constrain it.

The render produces an SVG at a path of your choosing; honor `DIAGRAM_OUTPUT_DIR` if set, otherwise default to the current working directory. Fireworks's workflow includes its own validation step (`rsvg-convert ... -o /dev/null`). Export PNG only when `output.formats` includes `png`, or when PNG is needed for `mode: powerpoint` or visual validation. Do not skip validation.

If you find yourself wanting to invoke `generate-from-template.py` with a structured `{ nodes[], arrows[], containers[] }` JSON, stop. That is a legacy path that produces narrower output than fireworks's free-form SVG composition. Use the SVG-authoring path fireworks's SKILL.md describes ("MANDATORY: Python List Method" or direct SVG composition).

### When `renderer == "drawio"`

The drawio path is fully self-contained in this plugin. Compose JSON of shape `{ title, subtitle?, nodes[], arrows[], containers[]?, legend[]? }` per the drawio builder's contract, then:

```bash
# build-drawio.py lives in this plugin:
#   <prima-delivery-root>/plugins/diagramming/scripts/build-drawio.py
python3 <plugin-root>/plugins/diagramming/scripts/build-drawio.py \
  <input.json> \
  "$OUTPUT_DIR/<slug>.drawio"

# Export PNG via the drawio CLI when output.formats includes "png" (brew install --cask drawio):
drawio --export --format png --scale 2 \
  --output "$OUTPUT_DIR/<slug>.png" \
  "$OUTPUT_DIR/<slug>.drawio"
```

Node `kind` values: `process`, `decision`, `data`, `terminator`. Arrow `kind` values: `control`, `data`, `feedback`. See `flow-diagrams/SKILL.md` Phase 3 (`When renderer == drawio`) for full composition advice including `lane` for nested feedback arcs and `exit_port` / `entry_port` / `waypoints[]` for explicit routing.

If `drawio` CLI is not on PATH and PNG was requested, deliver the `.drawio` file alone with the export failure. If PNG was not requested, the CLI is not required.

Phase 3 - Validate

For both renderers, validation is part of Phase 2's render step (fireworks: `rsvg-convert`; drawio: `drawio --export` exits non-zero on malformed XML). After Phase 2 completes, the file on disk is already validated. This phase exists for failure recovery semantics:

If the render fails, do not retry the same composition. Apply a targeted fix (or switch composition strategies - for fireworks, that's switching from templated to direct SVG authoring; for drawio, fixing the JSON shape). After three failures on a single diagram, stop and report the error to the user with file/line context.

Phase 4 - PowerPoint mode (when `mode == "powerpoint"`)

After every diagram in the input has been rendered (Phases 1-3 complete for each), assemble a deck:

1. Build a `deck-spec.json` in memory or in a temp file:

   ```jsonc
   {
     "title": "<deck.title>",
     "theme": "<deck.theme>",
     "author": "<deck.author>",
     "slides": [
       { "title": "<diagram.title>", "image": "<absolute path to PNG>", "notes": "<diagram.description>" }
     ]
   }
   ```

2. Invoke the deck builder:

   ```bash
   node plugins/diagramming/scripts/build-deck.js <deck-spec.json> "$OUTPUT_DIR/<deck-slug>.pptx"
   ```

   The deck builder uses [PptxGenJS](https://gitbrent.github.io/PptxGenJS/) - the from-scratch path Anthropic's `pptx` skill recommends (see `~/.claude/skills/anthropic-skills/skills/pptx/pptxgenjs.md`, or fetch from `anthropics/skills` on GitHub). PptxGenJS is declared in `plugins/diagramming/package.json`; run `npm install` once in that directory. Node 18+ required.

3. If `node` errors with "Cannot find module 'pptxgenjs'", tell the user to run `npm install` in `plugins/diagramming/`. Do not retry blindly.

4. Mixed-skill mode: if the user's request involves both `architecture-diagrams` AND `flow-diagrams`, the agent (`diagramming-engineer`) coordinates a single deck. Each skill renders its diagrams; only the last skill in the sequence builds the deck, accumulating slides from all renders by reading the manifest at `$OUTPUT_DIR/.deck-manifest.json`. (See `diagramming-engineer.md` for the cross-skill coordination protocol.)

Phase 5 - Visual validation (always run for drawio; optional for fireworks)

Same protocol as `flow-diagrams` Phase 5 (formerly Phase 6). Two layers:

- **Layer A (deterministic, fast):** `python3 plugins/diagramming/scripts/validate-diagram.py "$OUTPUT_DIR/<slug>.drawio"` checks every cell's text/fill contrast against WCAG AA (4.5:1). Exit 0 = pass, 1 = fail. Use `--threshold 7.0` for AAA. Currently accepts only `.drawio` input.
- **Layer B (richer, optional):** Dispatch the `ui-visual-validator` agent (`plugins/accessibility-compliance/agents/ui-visual-validator.md`) against the rendered PNG for typography readability, layout density, and color-blind safety beyond contrast. Use when the diagram is going into a customer-facing deliverable.

Layer A runs in <1s and catches the 80% case (bad contrast from custom `style_overrides`). Reach for layer B when audience matters.

Phase 6 - Diff-update path (when `diff` is present)

When a diagram entry has a non-null `diff`:

1. Read the prior SVG / `.drawio` from `output_dir/<slug>.{svg,drawio}` if it exists; if not, render from scratch.
2. Parse the unified diff to identify which `source` files changed and what the changes are.
3. Re-extract nodes/edges only for the changed regions and merge into the prior structure.
4. Re-render. Validate as in Phase 3 and Phase 5.
5. Report a one-paragraph diff summary alongside the updated diagram (what changed in the diagram and why).

## Output

For each diagram in the input, deliver only the requested final formats:

- Fireworks renderer: `svg`, `png`, or both. Default: `svg,png`.
- Drawio renderer: `drawio`, `png`, optional `svg` export when drawio CLI supports it. Default: `drawio,png`.
- PowerPoint mode: always produces `.pptx`; per-diagram image formats still follow `output.formats` unless the deck builder needs a PNG as an intermediate.
- A short prose description (what the diagram shows, key relationships) for the user.

`<slug>` is derived from `diagram.title` via lowercase + hyphenation; non-alphanumeric chars become hyphens; collapse repeats.

## Constraints

- Never invent structure. Every node and edge must trace back to a specific line in the source files or a specific user statement.
- Never deliver an SVG without `rsvg-convert` validation passing (fireworks renderer); never deliver a `.drawio` without well-formed XML validation. Never claim a PNG exists unless export succeeded.
- For fireworks: follow `fireworks-tech-graph`'s SKILL.md verbatim - its Diagram Types, Shape Vocabulary, Arrow Semantics, Layout Rules, and Styles 1-7. Do not constrain its composition to a structured `{ nodes[], arrows[] }` JSON shape; that produces narrower output than the renderer can natively support.
- Do not hardcode project names, paths, or credentials in any output. Read from input or env (`DIAGRAM_OUTPUT_DIR`, `DIAGRAM_OUTPUT_FORMATS`, `FIREWORKS_TECH_GRAPH_HOME`, `DIAGRAM_DEFAULT_RENDERER`, `DIAGRAM_DEFAULT_STYLE`, `DIAGRAM_DECK_TITLE`).
- Do not generate a diagram larger than fireworks-tech-graph's documented viewBox limits. If the input would exceed them, split into multiple diagrams and explain the split to the user.

## Coexistence with other agents

- The `c4-context`, `c4-container`, `c4-component`, `c4-code` agents in the `c4-architecture` plugin do code-level C4 synthesis. When the user asks for a C4 diagram and the source is a code repository, delegate the synthesis step to those agents, then feed their output into this skill for visual rendering.
- The `mermaid-expert` agent (in `.opencode/agents/`) produces raw Mermaid source for downstream consumers that need it. It is not a substitute for this skill in v1.
