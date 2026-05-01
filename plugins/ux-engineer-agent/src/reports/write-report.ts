import { writeFileSync, mkdirSync } from "fs"
import { join } from "path"
import type { LoopResult } from "../loop/run-polish-loop.js"

export interface Report {
  generatedAt: string
  status: LoopResult["status"]
  finalScore: number
  iterations: number
  scoreHistory: LoopResult["history"]
  routes: string[]
  dimensions: Array<{
    id: string
    finalScore: number
    finding: string
  }>
  patchSummary: string | null
}

export function writeReport(result: LoopResult, outputDir: string): Report {
  mkdirSync(outputDir, { recursive: true })

  const dimensions = result.evalResults.flatMap((r) =>
    r.dimensions.map((d) => ({
      route: r.route,
      id: d.id,
      finalScore: d.score,
      finding: d.finding,
    }))
  )

  const report: Report = {
    generatedAt: new Date().toISOString(),
    status: result.status,
    finalScore: result.finalScore,
    iterations: result.iterations,
    scoreHistory: result.history,
    routes: [...new Set(result.evalResults.map((r) => r.route))],
    dimensions,
    patchSummary: result.patchPlan?.summary ?? null,
  }

  writeFileSync(join(outputDir, "report.json"), JSON.stringify(report, null, 2), "utf-8")

  const statusIcon = { passed: "✓", maxed: "⚠", blocked: "✗" }[result.status]

  const md = `# UX Engineer Agent Report

**Status:** ${statusIcon} ${result.status.toUpperCase()}
**Final Score:** ${result.finalScore}/10
**Iterations:** ${result.iterations}
**Generated:** ${report.generatedAt}

## Score History

| Iteration | Score | Summary |
|-----------|-------|---------|
${result.history.map((h) => `| ${h.iteration} | ${h.score}/10 | ${h.summary.slice(0, 80)} |`).join("\n")}

## Dimension Scores (final)

${result.evalResults
  .map(
    (r) => `### ${r.route}
${r.dimensions
  .map((d) => `- **${d.id}** ${d.score}/10: ${d.finding}`)
  .join("\n")}
`
  )
  .join("\n")}

${result.patchPlan ? `## Patches Applied\n\n${result.patchPlan.summary}` : ""}
`

  writeFileSync(join(outputDir, "report.md"), md, "utf-8")

  console.log(`\n[ux-engineer] Report written to ${outputDir}/`)
  console.log(`  Status: ${statusIcon} ${result.status}  |  Score: ${result.finalScore}/10  |  Iterations: ${result.iterations}`)

  return report
}
