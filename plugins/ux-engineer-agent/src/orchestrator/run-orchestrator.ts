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
import { createPullRequest } from "../pr/create-pr.js"
import { writeReport } from "../reports/write-report.js"
import type { RouteScreenshot } from "../browser/crawl.js"
import type { EvalResult } from "../audit/score.js"
import type { PatchPlan } from "../patch/plan.js"
import type { ThemeProposal } from "./theme-gen.js"
import type { PrResult } from "../pr/create-pr.js"
import type { Config } from "../config.js"
import type { Rubric } from "../audit/rubric.js"

// ─── State ────────────────────────────────────────────────────────────────────

const OrchestratorState = Annotation.Root({
  iteration: Annotation<number>({ default: () => 0, reducer: (_, b) => b }),
  screenshots: Annotation<RouteScreenshot[]>({ default: () => [], reducer: (_, b) => b }),
  beforeScreenshots: Annotation<RouteScreenshot[]>({ default: () => [], reducer: (_, b) => b }),
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
  figmaFileUrl: Annotation<string>({ default: () => "", reducer: (_, b) => b }),
  prResult: Annotation<PrResult | null>({ default: () => null, reducer: (_, b) => b }),
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
  figmaFileUrl: string
  prResult: PrResult | null
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
      `\n[ux-engineer] Iteration ${state.iteration + 1} — capturing ${config.routes.length} route(s)...`
    )

    const screenshots = await crawl({
      baseUrl: config.appBaseUrl,
      routes: config.routes,
      outputDir: iterDir,
    })

    // Save the very first capture as the "before" baseline
    const isFirst = state.iteration === 0
    return {
      screenshots,
      iteration: state.iteration + 1,
      ...(isFirst ? { beforeScreenshots: screenshots } : {}),
    }
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

    const proposal = await generateThemes(state.evalResults, config.appBaseUrl, config.themeCount)

    console.log(`[ux-engineer] ${proposal.themes.length} themes generated`)
    proposal.themes.forEach((t) => {
      const rec = t.id === proposal.recommendedId ? " (recommended)" : ""
      console.log(`  - ${t.name}${rec}: ${t.personality}`)
    })

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
      figmaAccessToken: process.env.FIGMA_ACCESS_TOKEN,
    })

    if (result.figmaWritten) {
      const dest = result.figmaFileUrl ? `— ${result.figmaFileUrl}` : ""
      console.log(`[ux-engineer] Figma variables written ${dest}`)
    } else if (result.figmaError) {
      console.log(`[ux-engineer] Figma write skipped: ${result.figmaError}`)
    } else {
      console.log(`[ux-engineer] Tokens written to ${result.tokensPath} (set FIGMA_ACCESS_TOKEN to push)`)
    }

    return {
      tokensPath: result.tokensPath,
      figmaWritten: result.figmaWritten,
      figmaFileUrl: result.figmaFileUrl ?? "",
    }
  }

  async function prCreate(state: State): Promise<Partial<State>> {
    if (!config.raisePr || !config.targetRepoPath) {
      console.log(`[ux-engineer] PR creation skipped (set UX_AGENT_RAISE_PR=true and TARGET_REPO_PATH)`)
      return {}
    }

    console.log(`[ux-engineer] Creating pull request...`)

    const intermediateResult: OrchestratorResult = {
      status: state.score >= config.minScore ? "passed" : "maxed",
      finalScore: state.score,
      iterations: state.iteration,
      history: state.history,
      evalResults: state.evalResults,
      screenshots: state.screenshots,
      patchPlan: state.patchPlan,
      themeProposal: state.themeProposal,
      comparisonPath: state.comparisonPath,
      tokensPath: state.tokensPath,
      figmaWritten: state.figmaWritten,
      figmaFileUrl: state.figmaFileUrl,
      prResult: null,
      outputDir,
    }

    const prResult = await createPullRequest({
      result: intermediateResult,
      beforeScreenshots: state.beforeScreenshots,
      repoPath: config.targetRepoPath,
      branchName: process.env.UX_AGENT_PR_BRANCH,
      dryRun: config.dryRun,
    })

    if (prResult.skipped) {
      console.log(`[ux-engineer] PR skipped: ${prResult.skipReason}`)
    } else if (prResult.prUrl === "DRY_RUN") {
      console.log(`[ux-engineer] DRY RUN — PR would be created on branch ${prResult.branch}`)
    } else {
      console.log(`[ux-engineer] PR created: ${prResult.prUrl}`)
    }

    return { prResult }
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
    .addNode("prCreate", prCreate)
    .addEdge(START, "capture")
    .addEdge("capture", "eval")
    .addConditionalEdges("eval", afterEval, { patch: "patch", themeGen: "themeGen" })
    .addConditionalEdges("patch", afterPatch, { capture: "capture", themeGen: "themeGen" })
    .addEdge("themeGen", "comparison")
    .addEdge("comparison", "figmaWrite")
    .addEdge("figmaWrite", "prCreate")
    .addEdge("prCreate", END)
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
    figmaFileUrl: final.figmaFileUrl,
    prResult: final.prResult,
    outputDir,
  }
}
