import { chromium, type Browser, type Page } from "playwright"
import { join } from "path"
import { mkdirSync, existsSync } from "fs"

export interface RouteScreenshot {
  route: string
  url: string
  screenshotPath: string
  base64: string
  capturedAt: string
}

export interface CrawlOptions {
  baseUrl: string
  routes: string[]
  outputDir: string
  waitForSelector?: string
  viewportWidth?: number
  viewportHeight?: number
}

async function captureRoute(
  browser: Browser,
  url: string,
  outputPath: string,
  opts: Pick<CrawlOptions, "waitForSelector" | "viewportWidth" | "viewportHeight">
): Promise<string> {
  const page: Page = await browser.newPage()
  try {
    await page.setViewportSize({
      width: opts.viewportWidth ?? 1440,
      height: opts.viewportHeight ?? 900,
    })
    await page.goto(url, { waitUntil: "networkidle", timeout: 30_000 })

    if (opts.waitForSelector) {
      await page.waitForSelector(opts.waitForSelector, { timeout: 10_000 }).catch(() => {})
    }

    // Let animations settle
    await page.waitForTimeout(500)
    await page.screenshot({ path: outputPath, fullPage: true })
    return outputPath
  } finally {
    await page.close()
  }
}

export async function crawl(opts: CrawlOptions): Promise<RouteScreenshot[]> {
  if (!existsSync(opts.outputDir)) {
    mkdirSync(opts.outputDir, { recursive: true })
  }

  const browser = await chromium.launch({ headless: true })

  try {
    // Parallel capture — one browser context per route
    const results = await Promise.all(
      opts.routes.map(async (route): Promise<RouteScreenshot> => {
        const url = `${opts.baseUrl.replace(/\/$/, "")}${route}`
        const safeRoute = route.replace(/\//g, "_").replace(/^_/, "") || "root"
        const filename = `${safeRoute}_${Date.now()}.png`
        const screenshotPath = join(opts.outputDir, filename)

        await captureRoute(browser, url, screenshotPath, opts)

        const file = Bun.file(screenshotPath)
        const buffer = await file.arrayBuffer()
        const base64 = Buffer.from(buffer).toString("base64")

        return {
          route,
          url,
          screenshotPath,
          base64,
          capturedAt: new Date().toISOString(),
        }
      })
    )

    return results
  } finally {
    await browser.close()
  }
}
