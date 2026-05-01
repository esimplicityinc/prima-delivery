import { readFileSync, existsSync } from "fs"
import type { EvalResult } from "../audit/score.js"
import { callClaude } from "../llm/claude-cli.js"

export interface FilePatch {
  filePath: string
  originalContent: string
  patchedContent: string
  rationale: string
}

export interface PatchPlan {
  patches: FilePatch[]
  summary: string
}

const SYSTEM_PROMPT = `You are an expert frontend engineer specializing in Tailwind CSS, CSS custom properties, Astro components, and accessible UI design.
You receive UX audit findings with specific issues and dimension scores that must reach 9/10.
Your job: produce targeted, complete file patches that will raise every dimension score to at least 9/10.
Return ONLY valid JSON. No markdown. No explanation outside the JSON.`

export async function planPatches(
  evalResults: EvalResult[],
  writableStylePaths: string[],
  targetRepoPath: string
): Promise<PatchPlan> {
  const fileContents: Record<string, string> = {}
  for (const p of writableStylePaths) {
    const fullPath = targetRepoPath ? `${targetRepoPath}/${p}` : p
    if (existsSync(fullPath)) {
      fileContents[p] = readFileSync(fullPath, "utf-8")
    }
  }

  const findingsSummary = evalResults
    .map(
      (r) =>
        `Route: ${r.route} (score: ${r.weightedScore}/10)\n${r.overallSummary}\n\nDimension fixes needed:\n${r.dimensions
          .filter((d) => d.score < 9)
          .map((d) => `- [${d.id}] score ${d.score}/10: ${d.fix}`)
          .join("\n")}`
    )
    .join("\n\n---\n\n")

  const fileContext =
    Object.keys(fileContents).length > 0
      ? `\n\nCurrent file contents (patch these files):\n${Object.entries(fileContents)
          .map(([path, content]) => `\`\`\`\n// ${path}\n${content}\n\`\`\``)
          .join("\n\n")}`
      : "\n\nNo writable style files provided — suggest generic Tailwind/CSS fixes."

  const prompt = `UX Audit Findings requiring patches to reach 9/10 on every dimension:

${findingsSummary}

Writable files: ${writableStylePaths.join(", ") || "none specified"}
${fileContext}

Produce a JSON patch plan targeting a 9/10 UX score on ALL dimensions. Specific instructions:

1. CONTRAST (weight 2x): Ensure all text has 4.5:1 contrast ratio minimum. Replace low-contrast gray text with higher-contrast alternatives. Use CSS custom properties so changes cascade.

2. SPACING (weight 1.5x): Fix excessive whitespace on wide viewports. Add max-width constraints (max-w-2xl on login forms, max-w-4xl on dashboards). Tighten vertical padding on hero sections. Use Tailwind responsive variants.

3. HIERARCHY (weight 2x): Increase heading font-size differentiation. h1 should be 2.25rem+, h2 1.5rem+, body 1rem. Add font-weight 700 to primary headings. Ensure visual hierarchy is clear.

4. BRAND (weight 1.5x): Apply brand colors consistently. Primary CTAs must use brand primary. Secondary actions use outlined variant. No plain gray buttons where brand color is appropriate.

5. LAYOUT (weight 1x): Center content on wide screens. Add responsive grid where applicable. Avoid content wider than 1280px without padding.

6. DENSITY (weight 1x): Reduce excessive padding on login/auth pages. Max padding-y should be 2rem on focused forms. Content should fill 60-70% of viewport height at 1400px width.

DARK MODE: If the files include global.css or a Tailwind config:
- Add CSS custom properties for color tokens in :root
- Add .dark selector with inverted values
- Tailwind darkMode must be set to 'class'

ASTRO COMPONENTS: If .astro files are in the writable list:
- Add class="dark:..." variants to existing Tailwind classes
- Generate a DarkModeToggle.astro component if not present (use localStorage to persist preference)
- Apply max-width and spacing constraints directly to layout wrapper divs

Return JSON:
{
  "patches": [
    {
      "filePath": "<relative path>",
      "originalContent": "<verbatim current content>",
      "patchedContent": "<complete updated file content>",
      "rationale": "<which dimensions this patch fixes and how>"
    }
  ],
  "summary": "<1-2 sentences on total changes>"
}

Rules:
- Only patch files in the writable list above
- Each patch must include the COMPLETE updated file content, not a diff
- Add a DarkModeToggle.astro component as a new file if .astro files are writable and none exists
- Focus on the 2x-weighted dimensions (contrast, hierarchy) first
- Every change must directly address a specific audit dimension`

  const raw = await callClaude({
    system: SYSTEM_PROMPT,
    content: [{ type: "text", text: prompt }],
    maxTokens: 8192,
  })

  const cleaned = raw
    .replace(/^```(?:json)?\s*/m, "")
    .replace(/\s*```\s*$/m, "")
    .trim()

  try {
    return JSON.parse(cleaned) as PatchPlan
  } catch {
    return {
      patches: [],
      summary: `Failed to parse patch plan: ${raw.slice(0, 200)}`,
    }
  }
}
