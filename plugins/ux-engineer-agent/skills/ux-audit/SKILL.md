---
name: ux-audit
description: Runs a UX quality audit against a live web app using Claude vision. Captures screenshots of each route in parallel, evaluates them against a weighted rubric (contrast, spacing, hierarchy, brand, layout, density), and returns a score out of 10 with per-dimension findings and fix recommendations. Use when the user wants to audit, score, or get feedback on the UX quality of any web application.
version: 1.0.0
---

# UX Audit Skill

## What it audits

The audit evaluates screenshots against six weighted dimensions:

| Dimension | Weight | What it checks |
|-----------|--------|----------------|
| contrast | 2 | WCAG AA compliance for all text/background pairs |
| spacing | 1.5 | Visual rhythm, padding consistency, breathing room between elements |
| hierarchy | 2 | Clear primary/secondary/tertiary visual distinction — does the eye know where to go? |
| brand | 1.5 | Color consistency, professional identity, no rogue color values |
| layout | 1 | Alignment, grid discipline, negative space use |
| density | 1 | Information density relative to viewport — too sparse is as bad as too dense |

Weighted score out of 10. Pass threshold: 8 (configurable).

## How to run it

```bash
APP_BASE_URL="https://myapp.example.com" \
UX_AGENT_ROUTES="/,/dashboard,/settings" \
bun run src/cli.ts
```

Add `UX_AGENT_DRY_RUN=true` to see what patches would be applied without writing.

## What you get back

Each route returns:
- A score per dimension (1-10, clamped)
- A `finding` — what the AI literally sees in the screenshot (hex values, element names, contrast ratios)
- A `fix` — specific CSS/Tailwind to improve that dimension

The aggregate score is a weighted average across all routes and dimensions.

## Interpreting results

- **9-10**: Ship it. Minor polish only.
- **7-8**: Presentable. 1-2 iteration loop typically closes the gap.
- **5-6**: Significant issues. Brand or contrast failures likely. 2-3 iterations needed.
- **Below 5**: Foundational UX problems. Consider a theme redesign first, then patch.

The `density` and `brand` dimensions are the most common failure points for enterprise dashboards. `contrast` failures are the most likely to affect accessibility audits.

## Rubric customization

Override the rubric by setting `UX_AGENT_RUBRIC_PATH`. The schema requires:
- `dimensions[].id` — snake_case identifier
- `dimensions[].label` — display name
- `dimensions[].description` — what the dimension measures
- `dimensions[].weight` — numeric weight (higher = more influential)
- `dimensions[].signals` — array of strings that Claude uses as evaluation criteria
- `scoring.pass_threshold` — minimum weighted score to consider passing
