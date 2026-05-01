import type { Rubric } from "./rubric.js"

export interface DimensionScore {
  id: string
  score: number
  finding: string
  fix: string
}

export interface EvalResult {
  route: string
  dimensions: DimensionScore[]
  weightedScore: number
  overallSummary: string
  raw: string
}

export function parseScore(raw: string, rubric: Rubric, route: string): EvalResult {
  // Strip markdown code fences if model wrapped JSON
  const cleaned = raw
    .replace(/^```(?:json)?\s*/m, "")
    .replace(/\s*```\s*$/m, "")
    .trim()

  let parsed: Record<string, unknown>
  try {
    parsed = JSON.parse(cleaned)
  } catch {
    // Return low scores with the raw text as the finding — never crash
    const fallbackDimensions = rubric.dimensions.map((d) => ({
      id: d.id,
      score: 1,
      finding: "Failed to parse model response — treating as critical failure",
      fix: "Re-run evaluation",
    }))
    return {
      route,
      dimensions: fallbackDimensions,
      weightedScore: 1,
      overallSummary: `Parse error: ${raw.slice(0, 200)}`,
      raw,
    }
  }

  const rawDims = (parsed.dimensions ?? {}) as Record<
    string,
    { score: unknown; finding: unknown; fix: unknown }
  >

  const dimensions: DimensionScore[] = rubric.dimensions.map((d) => {
    const entry = rawDims[d.id] ?? {}
    const rawScore = typeof entry.score === "number" ? entry.score : 5
    // Clamp to rubric range
    const score = Math.max(
      rubric.scoring.min,
      Math.min(rubric.scoring.max, Math.round(rawScore))
    )
    return {
      id: d.id,
      score,
      finding: typeof entry.finding === "string" ? entry.finding : "No finding provided",
      fix: typeof entry.fix === "string" ? entry.fix : "No fix suggested",
    }
  })

  // Weighted average
  const totalWeight = rubric.dimensions.reduce((sum, d) => sum + d.weight, 0)
  const weightedScore =
    rubric.dimensions.reduce((sum, d) => {
      const dim = dimensions.find((x) => x.id === d.id)!
      return sum + dim.score * d.weight
    }, 0) / totalWeight

  return {
    route,
    dimensions,
    weightedScore: Math.round(weightedScore * 10) / 10,
    overallSummary:
      typeof parsed.overall_summary === "string"
        ? parsed.overall_summary
        : "No summary provided",
    raw,
  }
}

export function aggregateScores(results: EvalResult[]): number {
  if (results.length === 0) return 0
  const avg = results.reduce((sum, r) => sum + r.weightedScore, 0) / results.length
  return Math.round(avg * 10) / 10
}
