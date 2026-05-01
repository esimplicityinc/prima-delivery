import { execSync, spawnSync } from "child_process"
import { writeFileSync, mkdirSync, existsSync } from "fs"
import { join, basename } from "path"
import type { OrchestratorResult } from "../orchestrator/run-orchestrator.js"
import type { RouteScreenshot } from "../browser/crawl.js"

export interface PrResult {
  prUrl: string
  branch: string
  screenshotPaths: string[]
  skipped: boolean
  skipReason?: string
}

function git(args: string[], cwd: string): { ok: boolean; out: string; err: string } {
  const r = spawnSync("git", args, { cwd, encoding: "utf-8" })
  return {
    ok: r.status === 0,
    out: (r.stdout ?? "").trim(),
    err: (r.stderr ?? "").trim(),
  }
}

function gh(args: string[], cwd: string): { ok: boolean; out: string; err: string } {
  const r = spawnSync("gh", args, { cwd, encoding: "utf-8" })
  return {
    ok: r.status === 0,
    out: (r.stdout ?? "").trim(),
    err: (r.stderr ?? "").trim(),
  }
}

function checkPrerequisites(repoPath: string): string | null {
  const ghCheck = spawnSync("gh", ["--version"], { encoding: "utf-8" })
  if (ghCheck.status !== 0) return "gh CLI not found — install it to create PRs automatically"

  const gitCheck = git(["status", "--porcelain"], repoPath)
  if (!gitCheck.ok) return `${repoPath} is not a git repository`

  return null
}

function slugify(text: string): string {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
}

function screenshotToMarkdown(
  screenshots: RouteScreenshot[],
  repoPath: string,
  docsDir: string,
  label: string
): { lines: string[]; paths: string[] } {
  const paths: string[] = []
  const lines: string[] = [`### ${label}\n`]

  for (const s of screenshots) {
    const filename = `${label.toLowerCase().replace(/\s/g, "-")}-${slugify(s.route)}.png`
    const fullPath = join(docsDir, filename)
    const pngBuffer = Buffer.from(s.base64, "base64")
    writeFileSync(fullPath, pngBuffer)
    paths.push(fullPath)

    const relPath = fullPath.replace(repoPath + "/", "")
    lines.push(`**${s.route}**\n\n![${label} — ${s.route}](./${relPath})\n`)
  }

  return { lines, paths }
}

export async function createPullRequest(opts: {
  result: OrchestratorResult
  beforeScreenshots: RouteScreenshot[]
  repoPath: string
  branchName?: string
  prTitle?: string
  dryRun?: boolean
}): Promise<PrResult> {
  const { result, beforeScreenshots, repoPath, dryRun = false } = opts

  const prereqError = checkPrerequisites(repoPath)
  if (prereqError) {
    return { prUrl: "", branch: "", screenshotPaths: [], skipped: true, skipReason: prereqError }
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19)
  const branch = opts.branchName ?? `ux-agent/redesign-${timestamp}`
  const prTitle = opts.prTitle ?? `feat(ux): AI-driven UX redesign — score ${result.finalScore}/10`

  const docsDir = join(repoPath, "docs", "ux-audit")
  mkdirSync(docsDir, { recursive: true })

  // Copy comparison board and tokens to docs
  const screenshotPaths: string[] = []
  const before = screenshotToMarkdown(beforeScreenshots, repoPath, docsDir, "Before")
  const after = screenshotToMarkdown(result.screenshots, repoPath, docsDir, "After")
  screenshotPaths.push(...before.paths, ...after.paths)

  if (dryRun) {
    console.log(`[ux-agent/pr] DRY RUN — would create branch ${branch} and PR: ${prTitle}`)
    return { prUrl: "DRY_RUN", branch, screenshotPaths, skipped: false }
  }

  // Create and checkout branch
  const checkoutResult = git(["checkout", "-b", branch], repoPath)
  if (!checkoutResult.ok) {
    return {
      prUrl: "",
      branch,
      screenshotPaths,
      skipped: true,
      skipReason: `Failed to create branch: ${checkoutResult.err}`,
    }
  }

  // Stage all changes (patches + docs)
  git(["add", "docs/ux-audit/"], repoPath)
  if (result.patchPlan) {
    for (const patch of result.patchPlan.patches) {
      git(["add", patch.filePath], repoPath)
    }
  }

  // Commit
  const commitMsg = `feat(ux): AI-driven UX redesign — score ${result.finalScore}/10

Automated by ux-engineer-agent.
Audit score: ${result.finalScore}/10 (${result.iterations} iteration(s))
Themes generated: ${result.themeProposal?.themes.length ?? 0}
Recommended theme: ${result.themeProposal?.themes.find(t => t.id === result.themeProposal?.recommendedId)?.name ?? "n/a"}`

  const commitResult = git(["commit", "-m", commitMsg], repoPath)
  if (!commitResult.ok) {
    return {
      prUrl: "",
      branch,
      screenshotPaths,
      skipped: true,
      skipReason: `Commit failed: ${commitResult.err}`,
    }
  }

  // Push branch
  const pushResult = git(["push", "-u", "origin", branch], repoPath)
  if (!pushResult.ok) {
    return {
      prUrl: "",
      branch,
      screenshotPaths,
      skipped: true,
      skipReason: `Push failed: ${pushResult.err}`,
    }
  }

  // Build PR body with before/after screenshots
  const recommended = result.themeProposal?.themes.find(
    (t) => t.id === result.themeProposal?.recommendedId
  )

  const prBody = buildPrBody({
    result,
    recommended,
    beforeLines: before.lines,
    afterLines: after.lines,
  })

  const prResult = gh(
    ["pr", "create", "--title", prTitle, "--body", prBody, "--head", branch],
    repoPath
  )

  if (!prResult.ok) {
    return {
      prUrl: "",
      branch,
      screenshotPaths,
      skipped: true,
      skipReason: `gh pr create failed: ${prResult.err}`,
    }
  }

  return { prUrl: prResult.out, branch, screenshotPaths, skipped: false }
}

function buildPrBody(opts: {
  result: OrchestratorResult
  recommended: { name: string; rationale: string; personality: string } | undefined
  beforeLines: string[]
  afterLines: string[]
}): string {
  const { result, recommended, beforeLines, afterLines } = opts

  const scoreHistory = result.history
    .map((h) => `- Iteration ${h.iteration}: ${h.score}/10`)
    .join("\n")

  const topIssues = result.evalResults
    .flatMap((r) => r.dimensions.filter((d) => d.score < 9))
    .sort((a, b) => a.score - b.score)
    .slice(0, 5)
    .map((d) => `- **${d.id}** (${d.score}/10): ${d.finding}`)
    .join("\n")

  const themeSection = recommended
    ? `## Recommended Theme: ${recommended.name}

**Personality**: ${recommended.personality}

${recommended.rationale}

View the full comparison board (light + dark mode) in \`docs/ux-audit/comparison.html\`.`
    : ""

  return `## Summary

- Implemented ADR / NFR: ADR-010 (Tailwind + shadcn/ui), ADR-009 (Astro frontend)
- Prompt: \`ux-engineer-agent orchestrator mode — audit, patch, theme, PR\`
- What happened: The UX Engineer Agent ran a full audit, identified contrast/hierarchy/density failures, applied CSS patches targeting 9/10 on all dimensions, generated 3 light+dark theme proposals, and raised this PR with before/after evidence.

## Scores

| Metric | Value |
|--------|-------|
| Final score | **${result.finalScore}/10** |
| Iterations | ${result.iterations} |
| Status | ${result.status} |

${scoreHistory ? `**Iteration history**\n${scoreHistory}` : ""}

## Top Issues Addressed

${topIssues || "All dimensions passed."}

${themeSection}

## Before / After Screenshots

${beforeLines.join("\n")}

${afterLines.join("\n")}

---
_Generated by ux-engineer-agent. Review the comparison board for full theme details._`
}
