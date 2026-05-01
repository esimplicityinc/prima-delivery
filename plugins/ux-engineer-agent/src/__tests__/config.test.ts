import { describe, it, expect, beforeEach, afterEach } from "vitest"

const REQUIRED = {
  APP_BASE_URL: "https://example.com",
  UX_AGENT_ROUTES: "/,/about",
}

function setEnv(vars: Record<string, string>) {
  for (const [k, v] of Object.entries(vars)) process.env[k] = v
}

function clearEnv() {
  for (const k of [
    "APP_BASE_URL", "UX_AGENT_ROUTES",
    "TARGET_REPO_PATH", "UX_AGENT_WRITABLE_STYLE_PATHS",
    "UX_AGENT_MAX_ITERATIONS", "UX_AGENT_MIN_SCORE",
    "UX_AGENT_DRY_RUN", "UX_AGENT_REQUIRE_CLEAN_GIT",
  ]) {
    delete process.env[k]
  }
}

describe("loadConfig", () => {
  beforeEach(clearEnv)
  afterEach(clearEnv)

  it("loads valid config from env vars", async () => {
    setEnv(REQUIRED)
    const { loadConfig } = await import("../config.js")
    const config = loadConfig()
    expect(config.appBaseUrl).toBe("https://example.com")
    expect(config.routes).toEqual(["/", "/about"])
    expect(config.maxIterations).toBe(4)
    expect(config.dryRun).toBe(false)
  })

  it("throws listing ALL missing vars when all are absent", async () => {
    const { loadConfig } = await import("../config.js")
    expect(() => loadConfig()).toThrow("Missing required environment variables: APP_BASE_URL, UX_AGENT_ROUTES")
  })

  it("throws naming only the single missing var", async () => {
    setEnv({ APP_BASE_URL: "https://example.com" })
    const { loadConfig } = await import("../config.js")
    expect(() => loadConfig()).toThrow("UX_AGENT_ROUTES")
  })

  it("parses UX_AGENT_DRY_RUN=true correctly", async () => {
    setEnv({ ...REQUIRED, UX_AGENT_DRY_RUN: "true" })
    const { loadConfig } = await import("../config.js")
    const config = loadConfig()
    expect(config.dryRun).toBe(true)
  })

  it("parses comma-separated routes", async () => {
    setEnv({ ...REQUIRED, UX_AGENT_ROUTES: "/shine/,/shine/content,/shine/admin" })
    const { loadConfig } = await import("../config.js")
    const config = loadConfig()
    expect(config.routes).toHaveLength(3)
    expect(config.routes[2]).toBe("/shine/admin")
  })
})
