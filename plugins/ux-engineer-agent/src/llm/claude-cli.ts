import { spawn } from "child_process"
import { existsSync } from "fs"

function resolveBin(): string {
  if (process.env.CLAUDE_CODE_EXECPATH) return process.env.CLAUDE_CODE_EXECPATH

  const candidates = ["/usr/local/bin/claude", "/opt/homebrew/bin/claude"]
  for (const p of candidates) {
    if (existsSync(p)) return p
  }

  throw new Error(
    "Cannot find the claude binary. Set CLAUDE_CODE_EXECPATH or ensure claude is on PATH."
  )
}

export interface TextContent {
  type: "text"
  text: string
}

export interface ImageContent {
  type: "image"
  source: { type: "base64"; media_type: "image/png"; data: string }
}

export type ContentBlock = TextContent | ImageContent

function hasImage(content: ContentBlock[]): boolean {
  return content.some((c) => c.type === "image")
}

function textOnly(content: ContentBlock[]): string {
  return content
    .filter((c): c is TextContent => c.type === "text")
    .map((c) => c.text)
    .join("\n\n")
}

// Vision call: uses stream-json input (required for image blocks)
function callWithImage(opts: {
  bin: string
  system: string
  content: ContentBlock[]
  model: string
  timeoutMs: number
}): Promise<string> {
  return new Promise((resolve, reject) => {
    const msg = JSON.stringify({
      type: "user",
      message: { role: "user", content: opts.content },
    })

    const args = [
      "-p", "--verbose",
      "--input-format", "stream-json",
      "--output-format", "stream-json",
      "--no-session-persistence",
      "--tools", "",
      "--system-prompt", opts.system,
      "--model", opts.model,
    ]

    const child = spawn(opts.bin, args, { stdio: ["pipe", "pipe", "pipe"] })
    let stdout = "", stderr = ""

    child.stdout.on("data", (d: Buffer) => { stdout += d.toString() })
    child.stderr.on("data", (d: Buffer) => { stderr += d.toString() })

    const timer = setTimeout(() => {
      child.kill("SIGTERM")
      reject(new Error(`Claude CLI (vision) timed out after ${opts.timeoutMs / 1000}s`))
    }, opts.timeoutMs)

    child.on("close", (code) => {
      clearTimeout(timer)
      const lines = stdout.split("\n").filter(Boolean)
      for (const line of lines) {
        try {
          const obj = JSON.parse(line)
          if (obj.type === "result" && obj.subtype === "success") {
            resolve(String(obj.result ?? ""))
            return
          }
          if (obj.type === "result" && obj.is_error) {
            reject(new Error(`Claude CLI error: ${obj.result ?? JSON.stringify(obj)}`))
            return
          }
        } catch (e) {
          if (e instanceof SyntaxError) continue
          reject(e as Error)
          return
        }
      }
      reject(new Error(
        `No result from Claude CLI vision (exit ${code}).\nstdout: ${stdout.slice(0, 500)}\nstderr: ${stderr.slice(0, 500)}`
      ))
    })

    child.on("error", (err) => { clearTimeout(timer); reject(err) })
    child.stdin.write(msg)
    child.stdin.end()
  })
}

// Text call: plain -p mode, prompt passed as CLI argument — works for long responses
// (stdin piping in -p mode can hang; passing as arg is reliable)
function callTextOnly(opts: {
  bin: string
  system: string
  prompt: string
  model: string
  timeoutMs: number
}): Promise<string> {
  return new Promise((resolve, reject) => {
    const args = [
      "-p",
      "--no-session-persistence",
      "--system-prompt", opts.system,
      "--model", opts.model,
      opts.prompt,  // pass prompt as positional argument, not stdin
    ]

    const child = spawn(opts.bin, args, { stdio: ["ignore", "pipe", "pipe"] })
    let stdout = "", stderr = ""

    child.stdout.on("data", (d: Buffer) => { stdout += d.toString() })
    child.stderr.on("data", (d: Buffer) => { stderr += d.toString() })

    const timer = setTimeout(() => {
      child.kill("SIGTERM")
      reject(new Error(`Claude CLI (text) timed out after ${opts.timeoutMs / 1000}s`))
    }, opts.timeoutMs)

    child.on("close", (code) => {
      clearTimeout(timer)
      if (code === 0 || stdout.trim()) {
        const raw = stdout
          .replace(/^```(?:json)?\s*/m, "")
          .replace(/\s*```\s*$/m, "")
          .trim()
        resolve(raw)
        return
      }
      reject(new Error(
        `Claude CLI text mode failed (exit ${code}).\nstdout: ${stdout.slice(0, 300)}\nstderr: ${stderr.slice(0, 300)}`
      ))
    })

    child.on("error", (err) => { clearTimeout(timer); reject(err) })
  })
}

export function callClaude(opts: {
  system: string
  content: ContentBlock[]
  model?: string
  timeoutMs?: number
}): Promise<string> {
  const bin = resolveBin()
  const model = opts.model ?? "claude-sonnet-4-6"
  const timeoutMs = opts.timeoutMs ?? 300_000

  if (hasImage(opts.content)) {
    return callWithImage({ bin, system: opts.system, content: opts.content, model, timeoutMs })
  }

  return callTextOnly({
    bin,
    system: opts.system,
    prompt: textOnly(opts.content),
    model,
    timeoutMs,
  })
}
