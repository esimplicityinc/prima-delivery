import { describe, it, expect } from "vitest"
import { applyPatches } from "../patch/apply.js"
import { writeFileSync, readFileSync, mkdirSync, rmSync, existsSync } from "fs"
import { join } from "path"
import { tmpdir } from "os"

function makeTmpRepo(): string {
  const dir = join(tmpdir(), `ux-agent-test-${Date.now()}`)
  mkdirSync(dir, { recursive: true })
  return dir
}

const PATCH_PLAN = (filePath: string, content: string) => ({
  patches: [
    {
      filePath,
      originalContent: "/* original */",
      patchedContent: content,
      rationale: "Test patch",
    },
  ],
  summary: "Test summary",
})

describe("applyPatches", () => {
  it("dry-run: returns applied list but writes nothing", async () => {
    const dir = makeTmpRepo()
    const filePath = "styles/global.css"
    const fullPath = join(dir, filePath)
    mkdirSync(join(dir, "styles"), { recursive: true })
    writeFileSync(fullPath, "/* original */")

    const result = await applyPatches(
      PATCH_PLAN(filePath, "/* patched */"),
      dir,
      true,  // dryRun
      false  // requireCleanGit
    )

    expect(result.dryRun).toBe(true)
    expect(result.applied).toContain(filePath)
    // File should be unchanged
    expect(readFileSync(fullPath, "utf-8")).toBe("/* original */")

    rmSync(dir, { recursive: true })
  })

  it("applies patch when not dry-run and git check skipped", async () => {
    const dir = makeTmpRepo()
    const filePath = "styles/global.css"
    const fullPath = join(dir, filePath)
    mkdirSync(join(dir, "styles"), { recursive: true })
    writeFileSync(fullPath, "/* original */")

    const result = await applyPatches(
      PATCH_PLAN(filePath, "/* patched */"),
      dir,
      false, // dryRun
      false  // requireCleanGit — skip git check in test
    )

    expect(result.applied).toContain(filePath)
    expect(readFileSync(fullPath, "utf-8")).toBe("/* patched */")

    rmSync(dir, { recursive: true })
  })

  it("skips patch when target directory does not exist", async () => {
    const dir = makeTmpRepo()

    const result = await applyPatches(
      PATCH_PLAN("nonexistent/global.css", "/* patched */"),
      dir,
      false,
      false
    )

    expect(result.skipped).toContain("nonexistent/global.css")
    rmSync(dir, { recursive: true })
  })

  it("returns empty lists when patch plan has no patches", async () => {
    const result = await applyPatches(
      { patches: [], summary: "" },
      "/tmp",
      false,
      false
    )
    expect(result.applied).toHaveLength(0)
    expect(result.skipped).toHaveLength(0)
    expect(result.gitGuardBlocked).toBe(false)
  })
})
