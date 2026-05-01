import { z } from "zod"

const REQUIRED = [
  "APP_BASE_URL",
  "UX_AGENT_ROUTES",
] as const

const ConfigSchema = z.object({
  appBaseUrl: z.string().url(),
  routes: z.array(z.string().startsWith("/")),
  targetRepoPath: z.string().optional(),
  writableStylePaths: z.array(z.string()),
  maxIterations: z.number().int().min(1).max(10).default(4),
  minScore: z.number().min(1).max(10).default(9),
  themeCount: z.number().int().min(1).max(10).default(3),
  dryRun: z.boolean().default(false),
  requireCleanGit: z.boolean().default(true),
  rubricPath: z.string().optional(),
  raisePr: z.boolean().default(false),
  prBranch: z.string().optional(),
})

export type Config = z.infer<typeof ConfigSchema>

export function loadConfig(): Config {
  const missing = REQUIRED.filter((k) => !process.env[k])
  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(", ")}\n\nRequired:\n${REQUIRED.map((k) => `  ${k}`).join("\n")}`
    )
  }

  const routes = (process.env.UX_AGENT_ROUTES ?? "")
    .split(",")
    .map((r) => r.trim())
    .filter(Boolean)

  const writableStylePaths = (process.env.UX_AGENT_WRITABLE_STYLE_PATHS ?? "")
    .split(",")
    .map((p) => p.trim())
    .filter(Boolean)

  const raw = {
    appBaseUrl: process.env.APP_BASE_URL!,
    routes,
    targetRepoPath: process.env.TARGET_REPO_PATH,
    writableStylePaths,
    maxIterations: process.env.UX_AGENT_MAX_ITERATIONS
      ? Number(process.env.UX_AGENT_MAX_ITERATIONS)
      : 4,
    minScore: process.env.UX_AGENT_MIN_SCORE
      ? Number(process.env.UX_AGENT_MIN_SCORE)
      : 9,
    themeCount: process.env.UX_AGENT_THEME_COUNT
      ? Number(process.env.UX_AGENT_THEME_COUNT)
      : 3,
    dryRun: process.env.UX_AGENT_DRY_RUN === "true",
    requireCleanGit: process.env.UX_AGENT_REQUIRE_CLEAN_GIT !== "false",
    rubricPath: process.env.UX_AGENT_RUBRIC_PATH,
    raisePr: process.env.UX_AGENT_RAISE_PR === "true",
    prBranch: process.env.UX_AGENT_PR_BRANCH,
  }

  const result = ConfigSchema.safeParse(raw)
  if (!result.success) {
    const issues = result.error.issues
      .map((i) => `  ${i.path.join(".")}: ${i.message}`)
      .join("\n")
    throw new Error(`Configuration invalid:\n${issues}`)
  }

  return result.data
}
