import type { RouteScreenshot } from "../browser/crawl.js"
import type { Rubric } from "./rubric.js"
import { formatRubricForPrompt } from "./rubric.js"
import { parseScore } from "./score.js"
import { callClaude } from "../llm/claude-cli.js"

const SYSTEM_PROMPT = `You are an expert UX auditor reviewing a screenshot of a live web application.
Your job is to score the UX quality across multiple dimensions based on a rubric.
Be direct and specific. Reference what you actually see in the screenshot.
Return ONLY valid JSON — no markdown, no explanation outside the JSON object.`

export async function evaluate(
  screenshot: RouteScreenshot,
  rubric: Rubric
): Promise<ReturnType<typeof parseScore>> {
  const rubricText = formatRubricForPrompt(rubric)
  const dimensionIds = rubric.dimensions.map((d) => d.id)

  const userPrompt = `You are reviewing a screenshot of this URL: ${screenshot.url}

${rubricText}

Evaluate what you see in the screenshot and return a JSON object with this exact shape:
{
  "dimensions": {
    ${dimensionIds.map((id) => `"${id}": { "score": <number 1-10>, "finding": "<1-2 sentences on what you see>", "fix": "<specific CSS/Tailwind change to improve this>" }`).join(",\n    ")}
  },
  "overall_summary": "<2-3 sentences on the biggest issues>"
}

Be concrete. If you can see a specific problem, name it (e.g. "The header text #6b7280 on white fails WCAG AA at 4.6:1 contrast ratio"). If a dimension looks good, say so briefly.`

  const raw = await callClaude({
    system: SYSTEM_PROMPT,
    content: [
      {
        type: "image",
        source: { type: "base64", media_type: "image/png", data: screenshot.base64 },
      },
      { type: "text", text: userPrompt },
    ],
  })

  return parseScore(raw, rubric, screenshot.route)
}
