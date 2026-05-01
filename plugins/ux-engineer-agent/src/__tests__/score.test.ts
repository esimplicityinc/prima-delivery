import { describe, it, expect } from "vitest"
import { parseScore, aggregateScores } from "../audit/score.js"
import { loadRubric } from "../audit/rubric.js"
import { join } from "path"

const rubric = loadRubric(join(import.meta.dir, "../../rubric.json"))

function makeValidJson(overrides: Record<string, number> = {}) {
  const dims: Record<string, unknown> = {}
  for (const d of rubric.dimensions) {
    dims[d.id] = {
      score: overrides[d.id] ?? 8,
      finding: `Finding for ${d.id}`,
      fix: `Fix for ${d.id}`,
    }
  }
  return JSON.stringify({ dimensions: dims, overall_summary: "Looks OK" })
}

describe("parseScore", () => {
  it("parses a valid model response", () => {
    const result = parseScore(makeValidJson(), rubric, "/shine/")
    expect(result.route).toBe("/shine/")
    expect(result.dimensions.length).toBe(rubric.dimensions.length)
    expect(result.weightedScore).toBeGreaterThan(0)
  })

  it("clamps scores above 10 to 10", () => {
    const json = makeValidJson({ contrast: 15 })
    const result = parseScore(json, rubric, "/shine/")
    const contrastDim = result.dimensions.find((d) => d.id === "contrast")
    expect(contrastDim!.score).toBe(10)
  })

  it("clamps scores below 1 to 1", () => {
    const json = makeValidJson({ contrast: -5 })
    const result = parseScore(json, rubric, "/shine/")
    const contrastDim = result.dimensions.find((d) => d.id === "contrast")
    expect(contrastDim!.score).toBe(1)
  })

  it("returns fallback with score=1 on malformed JSON", () => {
    const result = parseScore("this is not json at all", rubric, "/shine/")
    expect(result.weightedScore).toBe(1)
    expect(result.overallSummary).toContain("Parse error")
  })

  it("strips markdown code fences before parsing", () => {
    const wrapped = `\`\`\`json\n${makeValidJson()}\n\`\`\``
    const result = parseScore(wrapped, rubric, "/shine/")
    expect(result.dimensions.length).toBeGreaterThan(0)
    expect(result.weightedScore).toBeGreaterThan(1)
  })
})

describe("aggregateScores", () => {
  it("returns 0 for empty array", () => {
    expect(aggregateScores([])).toBe(0)
  })

  it("averages scores across routes", () => {
    const r1 = parseScore(makeValidJson({ contrast: 6 }), rubric, "/a")
    const r2 = parseScore(makeValidJson({ contrast: 8 }), rubric, "/b")
    const avg = aggregateScores([r1, r2])
    expect(avg).toBeGreaterThan(0)
    expect(avg).toBeLessThanOrEqual(10)
  })
})
