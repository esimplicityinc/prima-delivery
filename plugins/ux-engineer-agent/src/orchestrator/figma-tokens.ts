import { writeFileSync } from "fs"
import { join } from "path"
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
    "color-dark": {
      primary: { $value: theme.darkPalette.primary, $type: "color", $description: "Primary brand color (dark mode)" },
      "primary-fg": { $value: theme.darkPalette.primaryFg, $type: "color" },
      secondary: { $value: theme.darkPalette.secondary, $type: "color" },
      accent: { $value: theme.darkPalette.accent, $type: "color" },
      background: { $value: theme.darkPalette.background, $type: "color", $description: "Dark page background" },
      surface: { $value: theme.darkPalette.surface, $type: "color", $description: "Dark card/panel background" },
      "text-primary": { $value: theme.darkPalette.textPrimary, $type: "color" },
      "text-secondary": { $value: theme.darkPalette.textSecondary, $type: "color" },
      border: { $value: theme.darkPalette.border, $type: "color" },
      error: { $value: theme.darkPalette.error, $type: "color" },
      success: { $value: theme.darkPalette.success, $type: "color" },
    },
  }
}

function hexToFigmaColor(hex: string): { r: number; g: number; b: number; a: number } {
  const clean = hex.replace("#", "")
  return {
    r: parseInt(clean.slice(0, 2), 16) / 255,
    g: parseInt(clean.slice(2, 4), 16) / 255,
    b: parseInt(clean.slice(4, 6), 16) / 255,
    a: 1,
  }
}

async function figmaFetch(path: string, accessToken: string, init?: RequestInit): Promise<Response> {
  return fetch(`https://api.figma.com/v1${path}`, {
    ...init,
    headers: {
      "X-Figma-Token": accessToken,
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
  })
}

// Figma REST API does not support file creation — the file must exist first.
// The user needs to create a blank Figma file and provide its key via FIGMA_FILE_KEY.
// Key is the alphanumeric segment in: figma.com/file/{KEY}/...
async function writeVariablesToFigma(opts: {
  theme: Theme
  fileKey: string
  accessToken: string
}): Promise<void> {
  const { theme, fileKey, accessToken } = opts

  const getRes = await figmaFetch(`/files/${fileKey}/variables/local`, accessToken)
  if (!getRes.ok) {
    const text = await getRes.text()
    throw new Error(`Figma GET variables failed (${getRes.status}): ${text.slice(0, 300)}`)
  }

  const existing = (await getRes.json()) as {
    meta?: { variableCollections?: Record<string, { id: string; name: string }> }
  }
  const collections = Object.values(existing.meta?.variableCollections ?? {})
  const collectionName = `UX Agent — ${theme.name}`
  const existingCollection = collections.find((c) => c.name === collectionName)
  const collectionId = existingCollection?.id ?? "ux-agent-new-collection"

  const allColors: Array<{ name: string; hex: string }> = [
    ...Object.entries(theme.palette).map(([k, v]) => ({ name: `light/${k}`, hex: v })),
    ...Object.entries(theme.darkPalette).map(([k, v]) => ({ name: `dark/${k}`, hex: v })),
  ]

  const variableCollections = existingCollection
    ? []
    : [{ action: "CREATE" as const, id: collectionId, name: collectionName, initialModeId: "default" }]

  const variables = allColors.map(({ name }, i) => ({
    action: "CREATE" as const,
    id: `ux-var-${i}`,
    name,
    variableCollectionId: collectionId,
    resolvedType: "COLOR" as const,
  }))

  const variableModeValues = allColors.map(({ hex }, i) => ({
    variableId: `ux-var-${i}`,
    modeId: "default",
    value: hexToFigmaColor(hex),
  }))

  const postRes = await figmaFetch(`/files/${fileKey}/variables`, accessToken, {
    method: "POST",
    body: JSON.stringify({ variableCollections, variables, variableModeValues }),
  })

  if (!postRes.ok) {
    const text = await postRes.text()
    throw new Error(`Figma POST variables failed (${postRes.status}): ${text.slice(0, 300)}`)
  }
}

export interface FigmaWriteResult {
  tokensPath: string
  figmaWritten: boolean
  figmaFileUrl?: string
  figmaError?: string
}

export async function writeFigmaTokens(opts: {
  theme: Theme
  outputDir: string
  figmaFileKey?: string
  figmaAccessToken?: string
  figmaTeamId?: string
}): Promise<FigmaWriteResult> {
  const { theme, outputDir } = opts
  const accessToken = opts.figmaAccessToken ?? process.env.FIGMA_ACCESS_TOKEN
  const fileKey = opts.figmaFileKey ?? process.env.FIGMA_FILE_KEY

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

  // Both access token AND file key required — Figma REST API has no file-creation endpoint
  if (!accessToken || !fileKey) {
    return { tokensPath, figmaWritten: false }
  }

  try {
    await writeVariablesToFigma({ theme, fileKey, accessToken })
    return {
      tokensPath,
      figmaWritten: true,
      figmaFileUrl: `https://www.figma.com/file/${fileKey}`,
    }
  } catch (err) {
    return {
      tokensPath,
      figmaWritten: false,
      figmaError: String(err instanceof Error ? err.message : err).slice(0, 300),
    }
  }
}
