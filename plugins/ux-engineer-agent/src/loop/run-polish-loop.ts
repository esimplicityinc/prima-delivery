import { StateGraph, START, END, Annotation } from "@langchain/langgraph"
import { crawl } from "../browser/crawl.js"
import { evaluate } from "../audit/evaluate.js"
import { aggregateScores } from "../audit/score.js"
import { planPatches } from "../patch/plan.js"
import { applyPatches } from "../patch/apply.js"
import type { RouteScreenshot } from "../browser/crawl.js"
import type { EvalResult } from "../audit/score.js"
import type { PatchPlan } from "../patch/plan.js"
import type { Config } from "../config.js"
import type { Rubric } from "../audit/rubric.js"
import { mkdirSync } from "fs"
import { join } from "path"

// ─── State ────────────────────────────────────────────────────────────────────

const PolishState = Annotation.Root({
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
})

type State = typeof PolishState.State

export interface LoopResult {
  status: "passed" | "maxed" | "blocked"
  finalScore: number
  iterations: number
  history: Array<{ iteration: number; score: number; summary: string }>
  evalResults: EvalResult[]
  screenshots: RouteScreenshot[]
  patchPlan: PatchPlan | null
}

// ─── Graph factory ────────────────────────────────────────────────────────────

export async function runPolishLoop(
  config: Config,
  rubric: Rubric,
  outputDir: string
): Promise<LoopResult> {

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

  // ── routing ─────────────────────────────────────────────────────────────────

  function afterEval(state: State): "patch" | "done" {
    if (state.score >= config.minScore) return "done"
    if (state.iteration >= config.maxIterations) return "done"
    return "patch"
  }

  function afterPatch(state: State): "capture" | "done" {
    if (state.blocked) return "done"
    return "capture"
  }

  // ── graph ───────────────────────────────────────────────────────────────────

  const graph = new StateGraph(PolishState)
    .addNode("capture", capture)
    .addNode("eval", evalNode)
    .addNode("patch", patch)
    .addEdge(START, "capture")
    .addEdge("capture", "eval")
    .addConditionalEdges("eval", afterEval, { patch: "patch", done: END })
    .addConditionalEdges("patch", afterPatch, { capture: "capture", done: END })
    .compile()

  const final = await graph.invoke({})

  let status: "passed" | "maxed" | "blocked" = "maxed"
  if (final.blocked) status = "blocked"
  else if (final.score >= config.minScore) status = "passed"

  return {
    status,
    finalScore: final.score,
    iterations: final.iteration,
    history: final.history,
    evalResults: final.evalResults,
    screenshots: final.screenshots,
    patchPlan: final.patchPlan,
  }
}
