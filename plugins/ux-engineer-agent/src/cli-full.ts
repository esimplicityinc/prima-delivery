#!/usr/bin/env bun
import { loadConfig } from "./config.js"
import { loadRubric } from "./audit/rubric.js"
import { runOrchestrator } from "./orchestrator/run-orchestrator.js"
import { join } from "path"

async function main() {
  console.log("[ux-engineer] Starting UX Engineer Agent (Full — audit + themes + Figma)")

  const config = loadConfig()
  const rubric = loadRubric(config.rubricPath)

  console.log(`[ux-engineer] Config:`)
  console.log(`  URL: ${config.appBaseUrl}`)
  console.log(`  Routes: ${config.routes.join(", ")}`)
  console.log(`  Max iterations: ${config.maxIterations}`)
  console.log(`  Min score: ${config.minScore}/10`)
  console.log(`  Dry run: ${config.dryRun}`)
  console.log(`  Target repo: ${config.targetRepoPath ?? "(none)"}`)
  console.log(`  Rubric: ${rubric.dimensions.length} dimensions`)
  console.log(`  Figma: ${process.env.FIGMA_FILE_KEY ? `file key set` : "no FIGMA_FILE_KEY (tokens.json only)"}`)

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-")
  const outputDir = join(
    process.env.UX_AGENT_OUTPUT_DIR ?? "./ux-agent-output",
    timestamp
  )

  const result = await runOrchestrator(config, rubric, outputDir)

  console.log(`\n[ux-engineer] Report written to ${outputDir}/`)
  if (result.comparisonPath) {
    console.log(`[ux-engineer] Comparison board: ${result.comparisonPath}`)
  }
  if (result.tokensPath) {
    console.log(`[ux-engineer] Design tokens: ${result.tokensPath}`)
  }
  if (result.themeProposal) {
    const rec = result.themeProposal.themes.find(
      (t) => t.id === result.themeProposal!.recommendedId
    )
    console.log(`[ux-engineer] Recommended theme: ${rec?.name ?? "unknown"}`)
  }

  const icon = result.status === "passed" ? "✓" : result.status === "blocked" ? "✗" : "⚠"
  console.log(
    `  Status: ${icon} ${result.status}  |  Score: ${result.finalScore}/10  |  Iterations: ${result.iterations}`
  )

  process.exit(result.status === "blocked" ? 2 : result.status === "passed" ? 0 : 1)
}

main().catch((err) => {
  console.error(`[ux-engineer] Fatal error: ${err.message}`)
  if (process.env.DEBUG) console.error(err.stack)
  process.exit(1)
})
