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

const SYSTEM_PROMPT = `You are an expert frontend engineer specializing in Tailwind CSS, CSS custom properties, and Astro/React component styling.
You receive UX audit findings with specific issues and proposed fixes.
Your job: produce minimal, targeted patches to CSS/Tailwind files that address the findings.
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
          .filter((d) => d.score < 8)
          .map((d) => `- [${d.id}] score ${d.score}: ${d.fix}`)
          .join("\n")}`
    )
    .join("\n\n---\n\n")

  const fileContext =
    Object.keys(fileContents).length > 0
      ? `\n\nCurrent file contents (these are the files you may patch):\n${Object.entries(
          fileContents
        )
          .map(([path, content]) => `\`\`\`\n// ${path}\n${content}\n\`\`\``)
          .join("\n\n")}`
      : "\n\nNo writable style files provided — suggest generic Tailwind/CSS fixes as comments."

  const prompt = `UX Audit Findings requiring patches:

${findingsSummary}

Writable files: ${writableStylePaths.join(", ") || "none specified"}
${fileContext}

Produce a JSON patch plan with this shape:
{
  "patches": [
    {
      "filePath": "<relative path matching one of the writable files>",
      "originalContent": "<the current file content, verbatim>",
      "patchedContent": "<the complete updated file content with fixes applied>",
      "rationale": "<what was changed and why>"
    }
  ],
  "summary": "<1-2 sentences on what was changed overall>"
}

Rules:
- Only patch files in the writable list
- Make minimal targeted changes — don't rewrite files that don't need changes
- Focus on the lowest-scoring dimensions first
- Prefer Tailwind utility classes over raw CSS when the file is a Tailwind config or component
- Each patch must include the COMPLETE updated file content, not a diff`

  const raw = await callClaude({
    system: SYSTEM_PROMPT,
    content: [{ type: "text", text: prompt }],
    maxTokens: 4096,
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
