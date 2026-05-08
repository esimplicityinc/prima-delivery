# Diagramming plugin evals

Three eval cases verify the rendering pipeline (translated input → fireworks-tech-graph → SVG → rsvg-convert → PNG) for the JSON shape this plugin standardizes on.

These cases do **not** test the AI translation step (source files → translated.json). That step is the responsibility of each SKILL.md's prompt and is exercised end-to-end by integration with a model.

## Cases

| Case | Skill exercised | Source artifact | Template |
|------|-----------------|-----------------|----------|
| `arch-from-k8s` | `architecture-diagrams` | `input.yaml` (k8s manifest) | `architecture` |
| `sequence-from-routes` | `flow-diagrams` | `routes.ts` (Elysia routes) | `sequence` |
| `erd-from-schema` | `flow-diagrams` | `schema.ts` (Drizzle schema) | `er-diagram` |

`arch-from-k8s` additionally exercises the diff-update path via `translated-v2.json` and `diff_update.must_contain_after_diff` in its invariants.

## Running

```bash
# from the prima-delivery repo root
bun run plugins/diagramming/evals/run-cases.ts
```

Output is written to `plugins/diagramming/evals/.out/<case>/<case>.svg` and `.png`.

## Prerequisites

- `bun` (already a prima-delivery dep)
- `python3` on PATH
- `rsvg-convert` (`brew install librsvg` / `apt-get install librsvg2-bin`)
- `fireworks-tech-graph` skill installed at `~/.claude/skills/fireworks-tech-graph` (default) or wherever `FIREWORKS_TECH_GRAPH_HOME` points

Install fireworks-tech-graph if missing:

```bash
npx skills add yizhiyanhua-ai/fireworks-tech-graph
```

## Adding a case

1. Create a new directory under `plugins/diagramming/evals/<case-name>/`.
2. Drop in a `translated.json` matching the `<template_type>` you'll declare in invariants. Reference fireworks-tech-graph's `scripts/generate-from-template.py` for the input shape.
3. Add `expected-invariants.json` with at minimum:
   - `template_type` (string)
   - `rsvg_validates: true`
   - `svg_must_contain_text` (array of substrings)
   - `min_png_bytes` (sanity floor)
4. Optional: add a `<diagram-type>-from-<source>` source file (`input.yaml`, `routes.ts`, `schema.ts`) that documents what the AI would consume in production. The runner does not read it; it's documentation for human reviewers.
5. Optional: add `translated-v2.json` and `expected-invariants.json[diff_update]` to exercise the diff-update path.
