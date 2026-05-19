# Diagramming plugin evals

Seven eval cases verify the rendering pipeline for the supported renderer paths: legacy structured fireworks input, free-form fireworks SVG ingestion, drawio XML generation, drawio contrast validation, prompt metadata preservation, and PowerPoint smoke output.

These cases do **not** call an AI model. The prompt-level cases preserve the exact user prompt and skill input so the skill boundary is regression-tested deterministically, while the LLM translation step remains an integration concern.

## Cases

| Case | Skill exercised | Source artifact | Renderer |
|------|-----------------|-----------------|----------|
| `arch-from-k8s` | `architecture-diagrams` | `input.yaml` (k8s manifest) | legacy fireworks structured input |
| `sequence-from-routes` | `flow-diagrams` | `routes.ts` (Elysia routes) | legacy fireworks structured input |
| `erd-from-schema` | `flow-diagrams` | `schema.ts` (Drizzle schema) | legacy fireworks structured input |
| `fireworks-freeform-svg` | `architecture-diagrams` | `fixture.svg` | free-form fireworks SVG ingestion |
| `flowchart-drawio-feedback` | `flow-diagrams` | `translated.json` | drawio |
| `flowchart-drawio-lanes` | `flow-diagrams` | `translated.json` | drawio lane auto-stagger |
| `tommy-shine-deployment` | `architecture-diagrams` | Tommy's PR #5 prompt + skill input | drawio |

`arch-from-k8s` additionally exercises the diff-update path via `translated-v2.json` and `diff_update.must_contain_after_diff` in its invariants.

`tommy-shine-deployment` preserves the exact prompt `Diagram the SHINE portal deployment from ~/repos/content-portal`, asserts that the skill input routes to `architecture-diagrams` with `renderer: drawio`, then renders the deterministic drawio spec that the skill uses for this dense deployment graph class.

## Running

```bash
# from the prima-delivery repo root
bun run plugins/diagramming/evals/run-cases.ts
```

Output is written to `plugins/diagramming/evals/.out/<case>/`.

## Prerequisites

- `bun` (already a prima-delivery dep)
- `python3` on PATH
- `rsvg-convert` (`brew install librsvg` / `apt-get install librsvg2-bin`)
- `fireworks-tech-graph` skill installed at `~/.claude/skills/fireworks-tech-graph` (default) or wherever `FIREWORKS_TECH_GRAPH_HOME` points
- `drawio` CLI for drawio PNG export

Install fireworks-tech-graph if missing:

```bash
npx skills add yizhiyanhua-ai/fireworks-tech-graph
```

## Adding a case

1. Create a new directory under `plugins/diagramming/evals/<case-name>/`.
2. Drop in the renderer input: `translated.json` for legacy fireworks or drawio, or `fixture.svg` for a free-form fireworks SVG case.
3. Add `expected-invariants.json` with at minimum:
   - `renderer` (`fireworks`, `fireworks-prerendered`, or `drawio`)
   - renderer-specific text invariants
   - `min_png_bytes` (sanity floor)
4. Optional: add `prompt.txt` plus `skill-input.json` and assert them via `prompt_file`, `prompt_must_equal`, `skill_input_file`, `expected_skill`, and `expected_renderer`.
5. Optional: add `translated-v2.json` and `expected-invariants.json[diff_update]` to exercise the diff-update path.
