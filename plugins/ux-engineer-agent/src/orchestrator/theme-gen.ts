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
  cssVariables: Record<string, string>
}

export interface ThemeProposal {
  themes: Theme[]
  recommendedId: string
  selectionReason: string
}

const SYSTEM_PROMPT = `You are an expert product designer and brand strategist.
You analyze UX audit findings and propose concrete color system alternatives.
Return ONLY valid JSON — no markdown, no explanation outside the JSON.
Every hex color must pass WCAG AA contrast against its paired background.`

export async function generateThemes(
  evalResults: EvalResult[],
  appBaseUrl: string
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

Based on these findings, propose 3 distinct, business-appropriate color themes that would significantly improve the UX score. Each theme should:
- Fix the specific contrast and brand issues identified in the audit
- Be coherent and professional (not garish or toy-like)
- Represent genuinely different design personalities (e.g., corporate-trust vs modern-bold vs clean-minimal)
- Have all colors pass WCAG AA contrast ratios

Return a JSON object with this exact shape:
{
  "themes": [
    {
      "id": "theme-1",
      "name": "Short display name (2-3 words)",
      "rationale": "1-2 sentences on what design problems this solves and why the palette works",
      "personality": "One adjective phrase (e.g., 'Trustworthy Enterprise')",
      "palette": {
        "primary": "#hex",
        "primaryFg": "#hex (text color on primary, must be WCAG AA)",
        "secondary": "#hex",
        "accent": "#hex",
        "background": "#hex",
        "surface": "#hex (card/panel background)",
        "textPrimary": "#hex (main body text, must be WCAG AA on background)",
        "textSecondary": "#hex (muted text, must be WCAG AA on background)",
        "border": "#hex",
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
      }
    }
  ],
  "recommendedId": "theme-N (the id of the best fit given the audit findings)",
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
    // Fallback: return a generic safe theme
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
        },
      ],
      recommendedId: "theme-1",
      selectionReason: `Failed to parse Claude response: ${raw.slice(0, 100)}`,
    }
    return fallback
  }
}
