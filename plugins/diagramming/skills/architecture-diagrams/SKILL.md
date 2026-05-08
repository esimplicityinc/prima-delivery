---
name: architecture-diagrams
description: Generate SVG + PNG architecture diagrams (system architecture, deployment topology, network, infrastructure) from k8s manifests, Terraform stacks, ADRs, or prose descriptions. Renders via the fireworks-tech-graph skill, validated by rsvg-convert. Use for visual structural diagrams; use flow-diagrams for sequence, ERD, state, and flowchart.
version: 1.0.0
---

# architecture-diagrams

Generate production-quality architecture, deployment, infrastructure, and network topology diagrams as SVG (with PNG export) by translating source material (k8s manifests, Terraform, ADRs, prose) into structured input for the `fireworks-tech-graph` skill, then validating the output with `rsvg-convert`.

## When to use this skill

Use this skill when the user asks for any of:

- A system architecture diagram (services + connections + data stores)
- A deployment topology (containers, pods, nodes, regions)
- An infrastructure diagram (VPCs, subnets, load balancers, cloud resources)
- A network topology (firewalls, routers, zones, traffic flow)
- A C4 context, container, or component diagram (visual representation; use the `c4-*` agents in `c4-architecture` for code-level synthesis first if needed)

For sequence diagrams, ERDs, state machines, flowcharts, or process flows, use the sibling `flow-diagrams` skill instead.

## Prerequisites

The skill requires two system tools. Check at startup; fail loudly with the install hint if missing:

- `rsvg-convert` — install: `brew install librsvg` (macOS) or `apt-get install librsvg2-bin` (Linux/Debian)
- `fireworks-tech-graph` skill — install: `npx skills add yizhiyanhua-ai/fireworks-tech-graph`

`python3` is also required (used by fireworks-tech-graph's helpers). Standard on most systems.

## Input contract

```jsonc
{
  "mode": "plain",                         // v1.0.0 ships plain only; "powerpoint" lands in a follow-up
  "output_dir": "./diagrams/",             // override with env: DIAGRAM_OUTPUT_DIR
  "style": 1,                               // 1-7 fireworks-tech-graph style; override with env: DIAGRAM_DEFAULT_STYLE

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

Environment variables override input fields when set. Required env vars fail loudly if missing in the contexts where they apply (`DIAGRAM_DECK_TITLE` is required only in powerpoint mode, which lands in a follow-up).

## Workflow

Phase 1 — Analyze input

1. Read source material listed under each diagram's `source` block. Do not infer structure; read the actual files.
2. For each diagram, extract:
   - Nodes (services, components, devices, resources)
   - Edges (connections, data flow, deployment relationships)
   - Layers / groups (zones, tiers, regions, namespaces)
   - Labels (names, types, ports, IPs as relevant to the diagram type)

Phase 2 — Translate to fireworks-tech-graph input

fireworks-tech-graph's renderer is **input-shape-uniform**: every template type consumes the same `{ title, subtitle, viewBox, nodes[], arrows[], containers[]?, legend[]? }` shape. The template-type argument only sets the default viewBox size and viewport conventions; it does not unlock new fields.

This means **the diagram type lives in how you compose `nodes` and `arrows`, not in a separate field**. Each node has `{ id, label, kind, x, y, width, height }`. Each arrow has `{ source, target, label?, kind? }`. `kind` on an arrow is one of fireworks-tech-graph's flow categories: `control`, `data`, `read`, `write`, `async`, `feedback`, `neutral`.

Composition by diagram type:

- `architecture` → horizontal layers. Place top-tier nodes (Client/Ingress) at small `y`, middle-tier (Services) at medium `y`, bottom-tier (Data) at large `y`. Snap `x` positions to a grid (~120px intervals). Optional `containers` for tier groupings.
- `network-topology` → tiered top-to-bottom (Internet → Edge → Core → Access → Endpoints). Use `containers` to draw zone boundaries (DMZ, Internal, Public).
- `deployment` → same shape as `architecture`. Add explicit node/instance labels per replica in the `label` text (e.g., `"frontend\n2 replicas"`).

Set viewBox per fireworks-tech-graph defaults: `"0 0 960 600"` standard, `"0 0 960 800"` for tall stacks. Pass it as the `viewBox` field (string).

Phase 3 — Generate

Invoke fireworks-tech-graph's templated helper:

```bash
python3 ~/.claude/skills/fireworks-tech-graph/scripts/generate-from-template.py \
  <template-type> \
  "$OUTPUT_DIR/<slug>.svg" \
  '<json>'
```

`<template-type>` is one of `architecture`, `network-topology` (use `architecture` for `deployment` — there is no separate template). The generator script's path defaults to `~/.claude/skills/fireworks-tech-graph/scripts/generate-from-template.py`; honor `FIREWORKS_TECH_GRAPH_HOME` if set.

If the diagram needs layout beyond `nodes` + `arrows` (rare; almost everything fits), fall back to authoring raw SVG via fireworks-tech-graph's Python list method ("MANDATORY: Python List Method" in its SKILL.md). Do not hand-author multi-line SVG strings — character truncation and tag mismatches are common.

Phase 4 — Validate + export

```bash
rsvg-convert "$OUTPUT_DIR/<slug>.svg" -o /dev/null && echo OK
rsvg-convert -w 1920 "$OUTPUT_DIR/<slug>.svg" -o "$OUTPUT_DIR/<slug>.png"
```

If validation fails, do not retry the same generation. Apply targeted fix (or switch from raw SVG to templated path), then re-validate. After three failures on a single diagram, stop and report the SVG syntax error to the user with line context.

Phase 5 — Diff-update path (when `diff` is present)

When a diagram entry has a non-null `diff`:

1. Read the prior SVG from `output_dir/<slug>.svg` if it exists; if not, render from scratch.
2. Parse the unified diff to identify which `source` files changed and what the changes are.
3. Re-extract nodes/edges only for the changed regions and merge into the prior structure.
4. Re-render. Validate as in Phase 4.
5. Report a one-paragraph diff summary alongside the updated SVG (what changed in the diagram and why).

## Output

For each diagram in the input:

- `<output_dir>/<slug>.svg` — primary artifact
- `<output_dir>/<slug>.png` — 1920px-wide export (2x retina)
- A short prose description (what the diagram shows, key relationships) for the user

`<slug>` is derived from `diagram.title` via lowercase + hyphenation; non-alphanumeric chars become hyphens; collapse repeats.

## Constraints

- Never invent structure. Every node and edge must trace back to a specific line in the source files or a specific user statement.
- Never deliver an SVG without `rsvg-convert` validation passing.
- Use fireworks-tech-graph's documented styles 1-7. Style choice flows from `style` in the input or `DIAGRAM_DEFAULT_STYLE` env var; default is style 1 (Flat Icon).
- Do not hardcode project names, paths, or credentials in any output. Read from input or env.
- Do not generate a diagram larger than fireworks-tech-graph's documented viewBox limits. If the input would exceed them, split into multiple diagrams and explain the split to the user.

## Coexistence with other agents

- The `c4-context`, `c4-container`, `c4-component`, `c4-code` agents in the `c4-architecture` plugin do code-level C4 synthesis. When the user asks for a C4 diagram and the source is a code repository, delegate the synthesis step to those agents, then feed their output into this skill for visual rendering.
- The `mermaid-expert` agent (in `.opencode/agents/`) produces raw Mermaid source for downstream consumers that need it. It is not a substitute for this skill in v1.
