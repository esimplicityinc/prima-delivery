import { describe, it, expect } from "vitest"
import { loadRubric } from "../audit/rubric.js"
import { join } from "path"
import { writeFileSync, rmSync } from "fs"
import { tmpdir } from "os"

const VALID_RUBRIC_PATH = join(import.meta.dir, "../../rubric.json")

describe("loadRubric", () => {
  it("loads the default rubric successfully", () => {
    const rubric = loadRubric(VALID_RUBRIC_PATH)
    expect(rubric.dimensions.length).toBeGreaterThan(0)
    expect(rubric.scoring.pass_threshold).toBe(8)
  })

  it("throws when rubric file does not exist", () => {
    expect(() => loadRubric("/tmp/nonexistent-rubric.json")).toThrow("Failed to read rubric")
  })

  it("throws with field name when dimension is missing required field", () => {
    const bad = {
      version: "1.0.0",
      dimensions: [{ id: "contrast" }], // missing label, description, weight, signals
      scoring: { min: 1, max: 10, pass_threshold: 8, dimension_score_meaning: {} },
    }
    const path = join(tmpdir(), `rubric-test-${Date.now()}.json`)
    writeFileSync(path, JSON.stringify(bad))
    try {
      expect(() => loadRubric(path)).toThrow("rubric.json validation failed")
    } finally {
      rmSync(path)
    }
  })

  it("throws when dimensions array is empty", () => {
    const bad = {
      version: "1.0.0",
      dimensions: [],
      scoring: { min: 1, max: 10, pass_threshold: 8, dimension_score_meaning: {} },
    }
    const path = join(tmpdir(), `rubric-test-empty-${Date.now()}.json`)
    writeFileSync(path, JSON.stringify(bad))
    try {
      expect(() => loadRubric(path)).toThrow("rubric.json validation failed")
    } finally {
      rmSync(path)
    }
  })

  it("all default dimensions have required signals", () => {
    const rubric = loadRubric(VALID_RUBRIC_PATH)
    for (const dim of rubric.dimensions) {
      expect(dim.signals.length).toBeGreaterThan(0)
      expect(dim.weight).toBeGreaterThan(0)
    }
  })
})
