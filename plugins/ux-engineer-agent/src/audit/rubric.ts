import { z } from "zod"
import { readFileSync } from "fs"
import { join, dirname } from "path"
import { fileURLToPath } from "url"

const DimensionSchema = z.object({
  id: z.string().min(1),
  label: z.string().min(1),
  description: z.string().min(1),
  weight: z.number().positive(),
  signals: z.array(z.string()).min(1),
})

const RubricSchema = z.object({
  version: z.string(),
  dimensions: z.array(DimensionSchema).min(1),
  scoring: z.object({
    min: z.number(),
    max: z.number(),
    pass_threshold: z.number(),
    dimension_score_meaning: z.record(z.string()),
  }),
})

export type Rubric = z.infer<typeof RubricSchema>
export type Dimension = z.infer<typeof DimensionSchema>

export function loadRubric(rubricPath?: string): Rubric {
  const path =
    rubricPath ??
    join(dirname(fileURLToPath(import.meta.url)), "../../rubric.json")

  let raw: unknown
  try {
    raw = JSON.parse(readFileSync(path, "utf-8"))
  } catch (err) {
    throw new Error(`Failed to read rubric at ${path}: ${(err as Error).message}`)
  }

  const result = RubricSchema.safeParse(raw)
  if (!result.success) {
    const issues = result.error.issues
      .map((i) => `  ${i.path.join(".")}: ${i.message}`)
      .join("\n")
    throw new Error(`rubric.json validation failed:\n${issues}`)
  }

  return result.data
}

export function formatRubricForPrompt(rubric: Rubric): string {
  const dims = rubric.dimensions
    .map(
      (d) =>
        `### ${d.label} (id: ${d.id}, weight: ${d.weight})\n${d.description}\n\nSignals to look for:\n${d.signals.map((s) => `- ${s}`).join("\n")}`
    )
    .join("\n\n")

  return `Score each dimension from ${rubric.scoring.min} to ${rubric.scoring.max}.
${rubric.scoring.max} = no visible issues. ${rubric.scoring.min} = critical problem.

Scoring guide:
${Object.entries(rubric.scoring.dimension_score_meaning)
  .map(([range, meaning]) => `- ${range}: ${meaning}`)
  .join("\n")}

## Dimensions

${dims}`
}
