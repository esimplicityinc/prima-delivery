import { writeFileSync } from "fs"
import { join } from "path"
import { callClaude } from "../llm/claude-cli.js"
import type { Theme } from "./theme-gen.js"

// W3C Design Token Community Group format (DTCG)
interface DtcgToken {
  $value: string
  $type: "color" | "dimension" | "fontFamily" | "shadow"
  $description?: string
}

function buildDtcgTokens(theme: Theme): Record<string, Record<string, DtcgToken>> {
  return {
    color: {
      primary: { $value: theme.palette.primary, $type: "color", $description: "Primary brand color" },
      "primary-fg": { $value: theme.palette.primaryFg, $type: "color", $description: "Text on primary" },
      secondary: { $value: theme.palette.secondary, $type: "color" },
      accent: { $value: theme.palette.accent, $type: "color" },
      background: { $value: theme.palette.background, $type: "color", $description: "Page background" },
      surface: { $value: theme.palette.surface, $type: "color", $description: "Card/panel background" },
      "text-primary": { $value: theme.palette.textPrimary, $type: "color", $description: "Main body text" },
      "text-secondary": { $value: theme.palette.textSecondary, $type: "color", $description: "Muted/helper text" },
      border: { $value: theme.palette.border, $type: "color" },
      error: { $value: theme.palette.error, $type: "color" },
      success: { $value: theme.palette.success, $type: "color" },
    },
  }
}

export interface FigmaWriteResult {
  tokensPath: string
  figmaWritten: boolean
  figmaError?: string
}

export async function writeFigmaTokens(opts: {
  theme: Theme
  outputDir: string
  figmaFileKey?: string
}): Promise<FigmaWriteResult> {
  const { theme, outputDir, figmaFileKey } = opts

  const dtcg = buildDtcgTokens(theme)
  const tokensPath = join(outputDir, "tokens.json")
  writeFileSync(
    tokensPath,
    JSON.stringify(
      {
        $metadata: {
          theme: theme.name,
          personality: theme.personality,
          generatedAt: new Date().toISOString(),
        },
        ...dtcg,
      },
      null,
      2
    ),
    "utf-8"
  )

  const fileKey = figmaFileKey ?? process.env.FIGMA_FILE_KEY
  if (!fileKey) {
    return { tokensPath, figmaWritten: false }
  }

  const figmaPrompt = `Use the Figma MCP tool to write design variables to Figma file key "${fileKey}".

Write the following color variables to a variable collection named "UX Agent — ${theme.name}":
${Object.entries(theme.palette)
  .map(([name, hex]) => `- ${name}: ${hex}`)
  .join("\n")}

If the collection already exists, update it. Confirm the variables were written.`

  try {
    await callClaude({
      system: "You are a design-token automation assistant. Use available MCP tools to complete the task.",
      content: [{ type: "text", text: figmaPrompt }],
      timeoutMs: 60_000,
    })
    return { tokensPath, figmaWritten: true }
  } catch (err) {
    return {
      tokensPath,
      figmaWritten: false,
      figmaError: String(err instanceof Error ? err.message : err).slice(0, 200),
    }
  }
}
