import { existsSync, writeFileSync } from "fs"
import { join } from "path"
import type { PatchPlan, FilePatch } from "./plan.js"

export interface ApplyResult {
  applied: string[]
  skipped: string[]
  dryRun: boolean
  gitGuardBlocked: boolean
}

async function isGitTreeClean(repoPath: string): Promise<boolean> {
  const proc = Bun.spawnSync(["git", "status", "--porcelain"], {
    cwd: repoPath,
    stdout: "pipe",
    stderr: "pipe",
  })
  if (proc.exitCode !== 0) {
    // Not a git repo or git not available — let it proceed
    return true
  }
  return proc.stdout.toString().trim() === ""
}

function resolveFilePath(patch: FilePatch, targetRepoPath?: string): string {
  if (targetRepoPath) {
    return join(targetRepoPath, patch.filePath)
  }
  return patch.filePath
}

export async function applyPatches(
  plan: PatchPlan,
  targetRepoPath: string | undefined,
  dryRun: boolean,
  requireCleanGit: boolean
): Promise<ApplyResult> {
  const result: ApplyResult = {
    applied: [],
    skipped: [],
    dryRun,
    gitGuardBlocked: false,
  }

  if (plan.patches.length === 0) {
    return result
  }

  // Git guard — check before any writes
  if (requireCleanGit && targetRepoPath && !dryRun) {
    const clean = await isGitTreeClean(targetRepoPath)
    if (!clean) {
      result.gitGuardBlocked = true
      console.error(
        `\n[ux-engineer] Git guard: ${targetRepoPath} has uncommitted changes.\n` +
          `Commit or stash them first, or set UX_AGENT_REQUIRE_CLEAN_GIT=false to bypass.\n`
      )
      return result
    }
  }

  for (const patch of plan.patches) {
    const fullPath = resolveFilePath(patch, targetRepoPath)

    if (dryRun) {
      console.log(`\n[DRY RUN] Would write: ${fullPath}`)
      console.log(`Rationale: ${patch.rationale}`)
      console.log(`--- patched content (first 500 chars) ---`)
      console.log(patch.patchedContent.slice(0, 500))
      result.applied.push(patch.filePath)
      continue
    }

    const dir = fullPath.substring(0, fullPath.lastIndexOf("/"))
    if (!existsSync(dir)) {
      console.warn(`[ux-engineer] Skipping ${patch.filePath} — directory does not exist: ${dir}`)
      result.skipped.push(patch.filePath)
      continue
    }

    writeFileSync(fullPath, patch.patchedContent, "utf-8")
    console.log(`[ux-engineer] Patched: ${fullPath}`)
    result.applied.push(patch.filePath)
  }

  return result
}
