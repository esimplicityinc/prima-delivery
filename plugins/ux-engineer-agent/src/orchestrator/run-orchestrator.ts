import { StateGraph, START, END, Annotation } from "@langchain/langgraph"
import { mkdirSync } from "fs"
import { join } from "path"
import { crawl } from "../browser/crawl.js"
import { evaluate } from "../audit/evaluate.js"
import { aggregateScores } from "../audit/score.js"
import { planPatches } from "../patch/plan.js"
import { applyPatches } from "../patch/apply.js"
import { generateThemes } from "./theme-gen.js"
import { writeComparisonBoard } from "./comparison.js"
import { writeFigmaTokens } from "./figma-tokens.js"
import { writeReport } from "../reports/write-report.js"
import type { RouteScreenshot } from "../browser/crawl.js"
import type { EvalResult } from "../audit/score.js"
import type { PatchPlan } from "../patch/plan.js"
import type { ThemeProposal } from "./theme-gen.js"
import type { Config } from "../config.js"
import type { Rubric } from "../audit/rubric.js"

// ─── State ────────────────────────────────────────────────────────────────────

const OrchestratorState = Annotation.Root({
  iteration: Annotation<number>({ default: () => 0, reducer: (_, b) => b }),
  screenshots: Annotation<RouteScreenshot[]>({ default: () => [], reducer: (_, b) => b }),
  evalResults: Annotation<EvalResult[]>({ default: () => [], reducer: (_, b) => b }),
  score: Annotation<number>({ default: () => 0, reducer: (_, b) => b }),
  patchPlan: Annotation<PatchPlan | null>({ default: () => null, reducer: (_, b) => b }),
  blocked: Annotation<boolean>({ default: () => false, reducer: (_, b) => b }),
  history: Annotation<Array<{ iteration: number; score: number; summary: string }>>({
    default: () => [],
    reducer: (a, b) => [...a, ...b],
  }),
  themeProposal: Annotation<ThemeProposal | null>({ default: () => null, reducer: (_, b) => b }),
  comparisonPath: Annotation<string>({ default: () => "", reducer: (_, b) => b }),
  tokensPath: Annotation<string>({ default: () => "", reducer: (_, b) => b }),
  figmaWritten: Annotation<boolean>({ default: () => false, reducer: (_, b) => b }),
})

type State = typeof OrchestratorState.State

export interface OrchestratorResult {
  status: "passed" | "maxed" | "blocked"
  finalScore: number
  iterations: number
  history: Array<{ iteration: number; score: number; summary: string }>
  evalResults: EvalResult[]
  screenshots: RouteScreenshot[]
  patchPlan: PatchPlan | null
  themeProposal: ThemeProposal | null
  comparisonPath: string
  tokensPath: string
  figmaWritten: boolean
  outputDir: string
}

// ─── Orchestrator ─────────────────────────────────────────────────────────────

export async function runOrchestrator(
  config: Config,
  rubric: Rubric,
  outputDir: string
): Promise<OrchestratorResult> {

  // ── nodes ──────────────────────────────────────────────────────────────────

  async function capture(state: State): Promise<Partial<State>> {
    const iterDir = join(outputDir, `iteration-${state.iteration + 1}`)
    mkdirSync(iterDir, { recursive: true })

    console.log(
      `\n[ux-engineer] Iteration ${state.iteration + 1} — capturing ${config.routes.length} route(s) in parallel...`
    )

    const screenshots = await crawl({
      baseUrl: config.appBaseUrl,
      routes: config.routes,
      outputDir: iterDir,
    })

    return { screenshots, iteration: state.iteration + 1 }
  }

  async function evalNode(state: State): Promise<Partial<State>> {
    console.log(
      `[ux-engineer] Evaluating ${state.screenshots.length} screenshot(s) with Claude vision...`
    )

    const evalResults = await Promise.all(
      state.screenshots.map((s) => evaluate(s, rubric))
    )

    const score = aggregateScores(evalResults)

    console.log(`[ux-engineer] Score: ${score}/10  (pass threshold: ${config.minScore}/10)`)
    evalResults.forEach((r) => {
      const low = r.dimensions.filter((d) => d.score < config.minScore)
      if (low.length)
        console.log(`  ${r.route}: ${low.map((d) => `${d.id}=${d.score}`).join(", ")}`)
      else
        console.log(`  ${r.route}: all dimensions pass`)
    })

    return {
      evalResults,
      score,
      history: [{ iteration: state.iteration, score, summary: evalResults[0]?.overallSummary ?? "" }],
    }
  }

  async function patch(state: State): Promise<Partial<State>> {
    const plan = await planPatches(
      state.evalResults,
      config.writableStylePaths,
      config.targetRepoPath ?? ""
    )

    console.log(`[ux-engineer] Patch plan: ${plan.patches.length} file(s)`)

    const applyResult = await applyPatches(
      plan,
      config.targetRepoPath,
      config.dryRun,
      config.requireCleanGit
    )

    return {
      patchPlan: plan,
      blocked: applyResult.gitGuardBlocked,
    }
  }

  async function themeGen(state: State): Promise<Partial<State>> {
    console.log(`\n[ux-engineer] Generating theme proposals...`)

    const proposal = await generateThemes(state.evalResults, config.appBaseUrl)

    console.log(`[ux-engineer] ${proposal.themes.length} themes generated`)
    proposal.themes.forEach((t) => {
      const rec = t.id === proposal.recommendedId ? " (recommended)" : ""
      console.log(`  - ${t.name}${rec}: ${t.personality}`)
    })

    const recommended = proposal.themes.find((t) => t.id === proposal.recommendedId)
    if (recommended) {
      console.log(`[ux-engineer] Recommendation: ${proposal.selectionReason}`)
    }

    return { themeProposal: proposal }
  }

  async function comparison(state: State): Promise<Partial<State>> {
    if (!state.themeProposal) return {}

    console.log(`[ux-engineer] Writing comparison board...`)

    const comparisonPath = writeComparisonBoard({
      proposal: state.themeProposal,
      screenshots: state.screenshots,
      outputDir,
      appBaseUrl: config.appBaseUrl,
      auditScore: state.score,
    })

    console.log(`[ux-engineer] Comparison board: ${comparisonPath}`)
    return { comparisonPath }
  }

  async function figmaWrite(state: State): Promise<Partial<State>> {
    if (!state.themeProposal) return {}

    const recommended = state.themeProposal.themes.find(
      (t) => t.id === state.themeProposal!.recommendedId
    )
    if (!recommended) return {}

    console.log(`[ux-engineer] Writing Figma tokens for "${recommended.name}"...`)

    const result = await writeFigmaTokens({
      theme: recommended,
      outputDir,
      figmaFileKey: process.env.FIGMA_FILE_KEY,
    })

    if (result.figmaWritten) {
      console.log(`[ux-engineer] Figma variables written successfully`)
    } else if (result.figmaError) {
      console.log(`[ux-engineer] Figma write skipped: ${result.figmaError}`)
    } else {
      console.log(`[ux-engineer] Tokens written to ${result.tokensPath} (set FIGMA_FILE_KEY to push to Figma)`)
    }

    return {
      tokensPath: result.tokensPath,
      figmaWritten: result.figmaWritten,
    }
  }

  // ── routing ─────────────────────────────────────────────────────────────────

  function afterEval(state: State): "patch" | "themeGen" {
    if (state.score >= config.minScore) return "themeGen"
    if (state.iteration >= config.maxIterations) return "themeGen"
    return "patch"
  }

  function afterPatch(state: State): "capture" | "themeGen" {
    if (state.blocked) return "themeGen"
    return "capture"
  }

  // ── graph ───────────────────────────────────────────────────────────────────

  const graph = new StateGraph(OrchestratorState)
    .addNode("capture", capture)
    .addNode("eval", evalNode)
    .addNode("patch", patch)
    .addNode("themeGen", themeGen)
    .addNode("comparison", comparison)
    .addNode("figmaWrite", figmaWrite)
    .addEdge(START, "capture")
    .addEdge("capture", "eval")
    .addConditionalEdges("eval", afterEval, { patch: "patch", themeGen: "themeGen" })
    .addConditionalEdges("patch", afterPatch, { capture: "capture", themeGen: "themeGen" })
    .addEdge("themeGen", "comparison")
    .addEdge("comparison", "figmaWrite")
    .addEdge("figmaWrite", END)
    .compile()

  const final = await graph.invoke({})

  let status: "passed" | "maxed" | "blocked" = "maxed"
  if (final.blocked) status = "blocked"
  else if (final.score >= config.minScore) status = "passed"

  writeReport(
    {
      status,
      finalScore: final.score,
      iterations: final.iteration,
      history: final.history,
      evalResults: final.evalResults,
      screenshots: final.screenshots,
      patchPlan: final.patchPlan,
    },
    outputDir
  )

  return {
    status,
    finalScore: final.score,
    iterations: final.iteration,
    history: final.history,
    evalResults: final.evalResults,
    screenshots: final.screenshots,
    patchPlan: final.patchPlan,
    themeProposal: final.themeProposal,
    comparisonPath: final.comparisonPath,
    tokensPath: final.tokensPath,
    figmaWritten: final.figmaWritten,
    outputDir,
  }
}
