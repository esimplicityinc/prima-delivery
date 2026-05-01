import { writeFileSync } from "fs"
import { join } from "path"
import type { ThemeProposal, Theme } from "./theme-gen.js"
import type { RouteScreenshot } from "../browser/crawl.js"

function colorSwatch(hex: string, label: string): string {
  return `<div class="swatch">
    <div class="swatch-block" style="background:${hex}"></div>
    <div class="swatch-label">${label}<br><span class="hex">${hex}</span></div>
  </div>`
}

function mockupHtml(palette: Theme["palette"], isDark: boolean): string {
  return `<div class="mockup" data-mode="${isDark ? "dark" : "light"}" style="background:${palette.background};border:1px solid ${palette.border};border-radius:8px;padding:20px;font-family:system-ui,sans-serif;">
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:16px;padding-bottom:12px;border-bottom:1px solid ${palette.border}">
      <div style="width:32px;height:32px;background:${palette.primary};border-radius:6px;display:flex;align-items:center;justify-content:center;">
        <div style="width:16px;height:16px;background:${palette.primaryFg};border-radius:2px;opacity:0.9"></div>
      </div>
      <span style="font-weight:700;color:${palette.textPrimary};font-size:16px">App Title</span>
    </div>
    <div style="background:${palette.surface};border:1px solid ${palette.border};border-radius:6px;padding:16px;margin-bottom:12px;">
      <p style="color:${palette.textPrimary};font-size:14px;font-weight:600;margin:0 0 4px">Main Heading</p>
      <p style="color:${palette.textSecondary};font-size:12px;margin:0 0 12px">Muted helper text demonstrating secondary tone.</p>
      <button style="background:${palette.primary};color:${palette.primaryFg};border:none;padding:8px 16px;border-radius:4px;font-size:13px;font-weight:600;cursor:pointer">Primary Action</button>
      <button style="background:transparent;color:${palette.primary};border:1px solid ${palette.primary};padding:8px 16px;border-radius:4px;font-size:13px;font-weight:600;margin-left:8px;cursor:pointer">Secondary</button>
    </div>
    <div style="display:flex;gap:8px;">
      <span style="background:${palette.accent};color:#fff;padding:3px 8px;border-radius:12px;font-size:11px;font-weight:600">Tag</span>
      <span style="background:${palette.success};color:#fff;padding:3px 8px;border-radius:12px;font-size:11px;font-weight:600">Success</span>
      <span style="background:${palette.error};color:#fff;padding:3px 8px;border-radius:12px;font-size:11px;font-weight:600">Error</span>
    </div>
  </div>`
}

function themeCard(theme: Theme, isRecommended: boolean): string {
  const badge = isRecommended ? `<span class="badge">Recommended</span>` : ""

  const lightSwatches = [
    { label: "Primary", hex: theme.palette.primary },
    { label: "Background", hex: theme.palette.background },
    { label: "Surface", hex: theme.palette.surface },
    { label: "Text", hex: theme.palette.textPrimary },
    { label: "Text Muted", hex: theme.palette.textSecondary },
    { label: "Accent", hex: theme.palette.accent },
  ]
    .map(({ label, hex }) => colorSwatch(hex, label))
    .join("")

  const darkSwatches = [
    { label: "Primary", hex: theme.darkPalette.primary },
    { label: "Background", hex: theme.darkPalette.background },
    { label: "Surface", hex: theme.darkPalette.surface },
    { label: "Text", hex: theme.darkPalette.textPrimary },
    { label: "Text Muted", hex: theme.darkPalette.textSecondary },
    { label: "Accent", hex: theme.darkPalette.accent },
  ]
    .map(({ label, hex }) => colorSwatch(hex, label))
    .join("")

  const lightMockup = mockupHtml(theme.palette, false)
  const darkMockup = mockupHtml(theme.darkPalette, true)

  const lightVars = Object.entries(theme.cssVariables)
    .map(([k, v]) => `  ${k}: ${v};`)
    .join("\n")

  const darkVars = Object.entries(theme.darkCssVariables)
    .map(([k, v]) => `  ${k}: ${v};`)
    .join("\n")

  return `<div class="theme-card${isRecommended ? " recommended" : ""}" data-theme-id="${theme.id}">
    <div class="theme-header">
      <h2>${theme.name} ${badge}</h2>
      <p class="personality">${theme.personality}</p>
      <p class="rationale">${theme.rationale}</p>
    </div>
    <div class="mockup-wrapper">
      <div class="mode-panel" data-panel="light">
        <p class="mode-label">Light Mode</p>
        ${lightMockup}
        <div class="swatches">${lightSwatches}</div>
      </div>
      <div class="mode-panel" data-panel="dark" style="display:none">
        <p class="mode-label">Dark Mode</p>
        ${darkMockup}
        <div class="swatches">${darkSwatches}</div>
      </div>
    </div>
    <details class="css-vars">
      <summary>CSS Variables</summary>
      <div class="vars-toggle">
        <button class="vars-btn active" data-vars="light" onclick="showVars(this,'light','${theme.id}')">Light</button>
        <button class="vars-btn" data-vars="dark" onclick="showVars(this,'dark','${theme.id}')">Dark</button>
      </div>
      <pre data-vars-panel="light-${theme.id}">:root {\n${lightVars}\n}</pre>
      <pre data-vars-panel="dark-${theme.id}" style="display:none">.dark {\n${darkVars}\n}</pre>
    </details>
  </div>`
}

function screenshotCard(screenshot: RouteScreenshot): string {
  return `<div class="screenshot-card">
    <h2>Current — ${screenshot.route}</h2>
    <p class="personality">As-is (before any changes)</p>
    <p class="rationale">Live screenshot captured during audit.</p>
    <div class="mockup-wrapper">
      <img src="data:image/png;base64,${screenshot.base64}" alt="Screenshot of ${screenshot.route}" style="width:100%;border-radius:8px;border:1px solid #e5e7eb"/>
    </div>
  </div>`
}

const TOGGLE_SCRIPT = `
<script>
  let isDark = false;

  function setMode(dark) {
    isDark = dark;
    document.querySelectorAll('[data-panel]').forEach(el => {
      const panel = el.getAttribute('data-panel');
      el.style.display = (dark ? panel === 'dark' : panel === 'light') ? '' : 'none';
    });
    document.getElementById('toggleBtn').textContent = dark ? '☀ Light Mode' : '☾ Dark Mode';
    document.body.style.background = dark ? '#0f172a' : '#f1f5f9';
    document.body.style.color = dark ? '#f1f5f9' : '#1e293b';
  }

  function showVars(btn, mode, themeId) {
    btn.closest('.css-vars').querySelectorAll('.vars-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    const details = btn.closest('.css-vars');
    details.querySelectorAll('[data-vars-panel]').forEach(el => {
      const key = el.getAttribute('data-vars-panel');
      el.style.display = key === mode + '-' + themeId ? '' : 'none';
    });
  }
</script>
`

export function writeComparisonBoard(opts: {
  proposal: ThemeProposal
  screenshots: RouteScreenshot[]
  outputDir: string
  appBaseUrl: string
  auditScore: number
}): string {
  const { proposal, screenshots, outputDir, appBaseUrl, auditScore } = opts

  const screenshotCards = screenshots.map(screenshotCard).join("")
  const themeCards = proposal.themes
    .map((t) => themeCard(t, t.id === proposal.recommendedId))
    .join("")

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UX Theme Comparison — ${appBaseUrl}</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, -apple-system, sans-serif; background: #f1f5f9; color: #1e293b; padding: 32px; transition: background 0.2s, color 0.2s; }
  .toolbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 32px; flex-wrap: wrap; gap: 12px; }
  h1 { font-size: 24px; font-weight: 700; }
  .meta { color: #64748b; font-size: 14px; }
  .meta strong { color: inherit; }
  #toggleBtn {
    background: #1e293b; color: #f8fafc; border: none; padding: 8px 18px;
    border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer;
    transition: background 0.2s;
  }
  #toggleBtn:hover { background: #334155; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(340px, 1fr)); gap: 24px; }
  .screenshot-card, .theme-card {
    background: #fff; border-radius: 12px; border: 1px solid #e2e8f0;
    padding: 24px; display: flex; flex-direction: column; gap: 16px;
  }
  .theme-card.recommended { border-color: #3b82f6; box-shadow: 0 0 0 2px #bfdbfe; }
  .theme-header h2 { font-size: 18px; font-weight: 700; display: flex; align-items: center; gap: 8px; }
  .badge { background: #3b82f6; color: #fff; font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 12px; }
  .personality { font-size: 12px; font-weight: 600; color: #6366f1; text-transform: uppercase; letter-spacing: 0.05em; margin-top: 4px; }
  .rationale { font-size: 13px; color: #475569; line-height: 1.5; margin-top: 4px; }
  .mode-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; }
  .swatches { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
  .swatch { display: flex; flex-direction: column; align-items: center; gap: 4px; }
  .swatch-block { width: 40px; height: 40px; border-radius: 6px; border: 1px solid rgba(0,0,0,0.08); }
  .swatch-label { font-size: 10px; text-align: center; color: #64748b; line-height: 1.3; }
  .hex { font-family: monospace; font-size: 10px; }
  .css-vars summary { font-size: 12px; font-weight: 600; color: #475569; cursor: pointer; padding: 4px 0; }
  .css-vars pre { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 12px; font-size: 11px; margin-top: 8px; overflow: auto; }
  .vars-toggle { display: flex; gap: 6px; margin: 8px 0; }
  .vars-btn { background: #f1f5f9; border: 1px solid #e2e8f0; color: #64748b; padding: 3px 10px; border-radius: 4px; font-size: 11px; cursor: pointer; }
  .vars-btn.active { background: #1e293b; color: #fff; border-color: #1e293b; }
  .selection-reason { background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 16px; margin-top: 32px; }
  .selection-reason h3 { font-size: 14px; font-weight: 600; color: #1d4ed8; margin-bottom: 4px; }
  .selection-reason p { font-size: 13px; color: #1e40af; }
</style>
</head>
<body>
<div class="toolbar">
  <div>
    <h1>UX Theme Comparison</h1>
    <p class="meta">
      <strong>${appBaseUrl}</strong> &nbsp;·&nbsp;
      Audit score: <strong>${auditScore}/10</strong> &nbsp;·&nbsp;
      ${proposal.themes.length} themes &nbsp;·&nbsp;
      Generated ${new Date().toLocaleString()}
    </p>
  </div>
  <button id="toggleBtn" onclick="setMode(!isDark)">☾ Dark Mode</button>
</div>
<div class="grid">
  ${screenshotCards}
  ${themeCards}
</div>
<div class="selection-reason">
  <h3>Recommendation: ${proposal.themes.find((t) => t.id === proposal.recommendedId)?.name ?? proposal.recommendedId}</h3>
  <p>${proposal.selectionReason}</p>
</div>
${TOGGLE_SCRIPT}
</body>
</html>`

  const outPath = join(outputDir, "comparison.html")
  writeFileSync(outPath, html, "utf-8")
  return outPath
}
