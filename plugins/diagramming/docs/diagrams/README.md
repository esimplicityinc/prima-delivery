# Hero diagrams produced by the diagramming plugin

These five diagrams are referenced in PR [#5](https://github.com/esimplicityinc/prima-delivery/pull/5) as proof-of-product. The RIC-401 appendix diagrams that were outside the RIC-353 scope were removed from this PR and should return in a separate RIC-401 PR.

## katalyst-thesis.{png,svg}

Plugin-rendered take on Aaron's Katalyst thesis: software only matters if it can prove value; enterprise and government users do not have SaaS-style agency, so usage alone proves nothing; Katalyst surfaces value at agent speed through the three taxonomy pillars.

Renderer: `drawio` via `plugins/diagramming/scripts/build-drawio.py`.

## katalyst-thesis-v2.{png,svg}

Hand-authored canonical reference for the expanded Katalyst thesis: cadence-direction matrix, cost-buffer collapse, authority outside the developer harness, and the visual design intent gap.

Renderer: hand-authored SVG reference, included so reviewers can compare plugin output against the canonical visual framing.

## 3-loop-process.{png,svg}

The RIC-401 three-loop design process: outer loop, inner feature design loop, and always-on hypothesis loop.

Renderer: `drawio` via `plugins/diagramming/scripts/build-drawio.py`.

## katalyst-taxonomy-dependencies.{png,svg}

Dependency graph of Katalyst artifact types organized by Need, Design Intent, and Implementation Reality.

Renderer: `drawio` via `plugins/diagramming/scripts/build-drawio.py`.

## shine-portal-deployment-v2.{png,svg,drawio}

The SHINE portal deployment topology generated from Tommy's exact PR #5 prompt:

```text
Diagram the SHINE portal deployment from ~/repos/content-portal
```

This is intentionally routed to `drawio`. The graph has CI/CD, auth/OIDC, Databricks runtime, browser traffic, and post-deploy verification lanes in one diagram, which is the dense graph class where fireworks auto-layout produced overlaps.

Regression fixture:

```text
plugins/diagramming/evals/tommy-shine-deployment/
```

Renderer: `architecture-diagrams` with `renderer: drawio`, then `build-drawio.py` plus drawio CLI PNG/SVG export.

## How to regenerate SHINE

```bash
CASE=plugins/diagramming/evals/tommy-shine-deployment
OUT=plugins/diagramming/docs/diagrams/shine-portal-deployment-v2

python3 plugins/diagramming/scripts/build-drawio.py "$CASE/translated.json" "$OUT.drawio"
python3 plugins/diagramming/scripts/validate-diagram.py "$OUT.drawio"
drawio --export --format png --scale 2 --output "$OUT.png" "$OUT.drawio"
drawio --export --format svg --output "$OUT.svg" "$OUT.drawio"
```

## Verification

```bash
bun run plugins/diagramming/evals/run-cases.ts
bun run plugins/diagramming/evals/run-routing-eval.ts
```
