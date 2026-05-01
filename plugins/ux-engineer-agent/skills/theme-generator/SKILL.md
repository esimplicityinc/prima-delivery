---
name: theme-generator
description: Generates 3 brand-appropriate color theme proposals from UX audit findings. Each theme includes a complete WCAG AA-passing palette, personality description, rationale tied to specific audit issues, and ready-to-use CSS custom properties. Use when the user wants to redesign the color system of a web app, improve brand consistency, or get theme alternatives to evaluate.
version: 1.0.0
---

# Theme Generator Skill

## What it produces

After a UX audit, the theme generator analyzes the findings and proposes 3 distinct color themes. Each theme is designed to directly address the issues found in the audit (contrast failures, brand inconsistency, missing visual hierarchy).

### Per theme

- **Name** — 2-3 word display name
- **Personality** — One adjective phrase (e.g., "Trustworthy Enterprise", "Modern Bold", "Clean Minimal")
- **Rationale** — 1-2 sentences tying the palette choices to specific audit findings
- **Palette** — 11 semantic color values with WCAG AA-passing contrast
- **CSS Variables** — Drop-in custom properties ready for a `:root {}` block

### Palette tokens

| Token | Purpose |
|-------|---------|
| `primary` | Primary brand/action color |
| `primary-fg` | Text on primary (must be WCAG AA) |
| `secondary` | Secondary brand color |
| `accent` | Highlight, tags, decorative elements |
| `background` | Page background |
| `surface` | Card/panel background |
| `text-primary` | Main body text (must be WCAG AA on background) |
| `text-secondary` | Muted/helper text (must be WCAG AA on background) |
| `border` | Input borders, dividers |
| `error` | Destructive actions, error states |
| `success` | Confirmation, positive states |

## What makes themes distinct

The three themes represent genuinely different design personalities, not just palette variations. For example:
- Theme 1 might be high-trust corporate (deep navy, clean white, subtle warmth)
- Theme 2 might be modern product (pure black, vibrant accent, generous whitespace)
- Theme 3 might be accessible-first neutral (softest palette that still passes WCAG AA everywhere)

## How to run theme generation

```bash
APP_BASE_URL="https://myapp.example.com" \
UX_AGENT_ROUTES="/,/dashboard" \
bun run src/cli-full.ts
```

Theme generation runs automatically after the polish loop in the full orchestrator.

## Output

The recommended theme's tokens are written to `tokens.json` in DTCG format. The HTML comparison board (`comparison.html`) shows all three themes side-by-side with live CSS mockups, so you can evaluate them visually before committing.

## Applying a theme

Copy the CSS variables block from the comparison board into your global stylesheet:

```css
:root {
  --color-primary: #1a56db;
  --color-primary-fg: #ffffff;
  /* ... */
}
```

Then reference these variables throughout your Tailwind config or component styles instead of hardcoded hex values.
