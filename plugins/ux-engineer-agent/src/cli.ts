#!/usr/bin/env bun
import { loadConfig } from "./config.js"
import { loadRubric } from "./audit/rubric.js"
import { runPolishLoop } from "./loop/run-polish-loop.js"
import { writeReport } from "./reports/write-report.js"
import { join } from "path"

async function main() {
  console.log("[ux-engineer] Starting UX Engineer Agent")

  // Fail loud on missing env vars — both loadConfig and loadRubric throw with clear messages
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

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-")
  const outputDir = join(
    process.env.UX_AGENT_OUTPUT_DIR ?? "./ux-agent-output",
    timestamp
  )

  const result = await runPolishLoop(config, rubric, outputDir)
  writeReport(result, outputDir)

  process.exit(result.status === "blocked" ? 2 : result.status === "passed" ? 0 : 1)
}

main().catch((err) => {
  console.error(`[ux-engineer] Fatal error: ${err.message}`)
  if (process.env.DEBUG) console.error(err.stack)
  process.exit(1)
})
