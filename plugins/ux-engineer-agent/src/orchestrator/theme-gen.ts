import { callClaude } from "../llm/claude-cli.js"
import type { EvalResult } from "../audit/score.js"

export interface ColorPalette {
  primary: string
  primaryFg: string
  secondary: string
  accent: string
  background: string
  surface: string
  textPrimary: string
  textSecondary: string
  border: string
  error: string
  success: string
}

export interface Theme {
  id: string
  name: string
  rationale: string
  personality: string
  palette: ColorPalette
  darkPalette: ColorPalette
  cssVariables: Record<string, string>
  darkCssVariables: Record<string, string>
}

export interface ThemeProposal {
  themes: Theme[]
  recommendedId: string
  selectionReason: string
}

const SYSTEM_PROMPT = `You are an expert product designer and brand strategist.
You analyze UX audit findings and propose concrete color system alternatives.
Return ONLY valid JSON — no markdown, no explanation outside the JSON.
Every hex color must pass WCAG AA contrast against its paired background.
Dark mode palettes must invert luminance while preserving brand identity.`

export async function generateThemes(
  evalResults: EvalResult[],
  appBaseUrl: string,
  themeCount = 3
): Promise<ThemeProposal> {
  const findingsSummary = evalResults
    .map(
      (r) =>
        `Route: ${r.route} (score: ${r.weightedScore}/10)\n${r.overallSummary}\n\nDimension details:\n${r.dimensions
          .map((d) => `- [${d.id}] ${d.score}/10: ${d.finding}`)
          .join("\n")}`
    )
    .join("\n\n---\n\n")

  const prompt = `You are analyzing a web application at: ${appBaseUrl}

UX Audit Findings:
${findingsSummary}

Based on these findings, propose ${themeCount} distinct, business-appropriate color themes. Each theme needs BOTH a light mode and a dark mode palette. Requirements:
- Fix the specific contrast and brand issues identified in the audit
- Be coherent and professional
- Represent genuinely different design personalities (e.g., corporate-trust vs modern-bold vs clean-minimal)
- All colors must pass WCAG AA contrast ratios in both light and dark mode
- Dark mode: invert backgrounds (light -> dark gray/near-black) while keeping brand primary recognizable

Return a JSON object with this exact shape:
{
  "themes": [
    {
      "id": "theme-1",
      "name": "Short display name (2-3 words)",
      "rationale": "1-2 sentences on what design problems this solves",
      "personality": "One adjective phrase (e.g., 'Trustworthy Enterprise')",
      "palette": {
        "primary": "#hex",
        "primaryFg": "#hex (text on primary, WCAG AA)",
        "secondary": "#hex",
        "accent": "#hex",
        "background": "#hex (light, e.g., #f9fafb or #ffffff)",
        "surface": "#hex (card background, slightly off-white)",
        "textPrimary": "#hex (dark, WCAG AA on background)",
        "textSecondary": "#hex (muted, WCAG AA on background)",
        "border": "#hex",
        "error": "#hex",
        "success": "#hex"
      },
      "darkPalette": {
        "primary": "#hex (slightly lighter than light primary for dark bg)",
        "primaryFg": "#hex",
        "secondary": "#hex",
        "accent": "#hex",
        "background": "#hex (very dark, e.g., #0f172a or #111827)",
        "surface": "#hex (dark surface, slightly lighter than background)",
        "textPrimary": "#hex (near-white, WCAG AA on dark background)",
        "textSecondary": "#hex (muted, WCAG AA on dark background)",
        "border": "#hex (dark border, subtle)",
        "error": "#hex",
        "success": "#hex"
      },
      "cssVariables": {
        "--color-primary": "#hex",
        "--color-primary-fg": "#hex",
        "--color-secondary": "#hex",
        "--color-accent": "#hex",
        "--color-bg": "#hex",
        "--color-surface": "#hex",
        "--color-text": "#hex",
        "--color-text-muted": "#hex",
        "--color-border": "#hex",
        "--color-error": "#hex",
        "--color-success": "#hex"
      },
      "darkCssVariables": {
        "--color-primary": "#hex",
        "--color-primary-fg": "#hex",
        "--color-secondary": "#hex",
        "--color-accent": "#hex",
        "--color-bg": "#hex",
        "--color-surface": "#hex",
        "--color-text": "#hex",
        "--color-text-muted": "#hex",
        "--color-border": "#hex",
        "--color-error": "#hex",
        "--color-success": "#hex"
      }
    }
  ],
  "recommendedId": "theme-N",
  "selectionReason": "One sentence on why this theme best addresses the audit findings"
}`

  const raw = await callClaude({
    system: SYSTEM_PROMPT,
    content: [{ type: "text", text: prompt }],
  })

  const cleaned = raw
    .replace(/^```(?:json)?\s*/m, "")
    .replace(/\s*```\s*$/m, "")
    .trim()

  try {
    return JSON.parse(cleaned) as ThemeProposal
  } catch {
    const fallback: ThemeProposal = {
      themes: [
        {
          id: "theme-1",
          name: "High Contrast Blue",
          rationale: "Addresses contrast failures with high-contrast primary and properly weighted typography.",
          personality: "Trustworthy Enterprise",
          palette: {
            primary: "#1a56db",
            primaryFg: "#ffffff",
            secondary: "#1e429f",
            accent: "#0694a2",
            background: "#f9fafb",
            surface: "#ffffff",
            textPrimary: "#111928",
            textSecondary: "#4b5563",
            border: "#e5e7eb",
            error: "#e02424",
            success: "#057a55",
          },
          darkPalette: {
            primary: "#4d8ef0",
            primaryFg: "#ffffff",
            secondary: "#3b6fd4",
            accent: "#22d3ee",
            background: "#0f172a",
            surface: "#1e293b",
            textPrimary: "#f1f5f9",
            textSecondary: "#94a3b8",
            border: "#334155",
            error: "#f87171",
            success: "#34d399",
          },
          cssVariables: {
            "--color-primary": "#1a56db",
            "--color-primary-fg": "#ffffff",
            "--color-secondary": "#1e429f",
            "--color-accent": "#0694a2",
            "--color-bg": "#f9fafb",
            "--color-surface": "#ffffff",
            "--color-text": "#111928",
            "--color-text-muted": "#4b5563",
            "--color-border": "#e5e7eb",
            "--color-error": "#e02424",
            "--color-success": "#057a55",
          },
          darkCssVariables: {
            "--color-primary": "#4d8ef0",
            "--color-primary-fg": "#ffffff",
            "--color-secondary": "#3b6fd4",
            "--color-accent": "#22d3ee",
            "--color-bg": "#0f172a",
            "--color-surface": "#1e293b",
            "--color-text": "#f1f5f9",
            "--color-text-muted": "#94a3b8",
            "--color-border": "#334155",
            "--color-error": "#f87171",
            "--color-success": "#34d399",
          },
        },
      ],
      recommendedId: "theme-1",
      selectionReason: `Failed to parse Claude response: ${raw.slice(0, 100)}`,
    }
    return fallback
  }
}
