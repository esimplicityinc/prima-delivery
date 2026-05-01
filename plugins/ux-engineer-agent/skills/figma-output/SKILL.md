---
name: figma-output
description: Exports design tokens from the UX Engineer Agent to Figma. Writes a DTCG-compliant tokens.json for any tool (Style Dictionary, Token Pipeline, Figma Tokens Plugin). If FIGMA_FILE_KEY is set and the Figma MCP server is configured in Claude Code, pushes color variables directly to the Figma file. Use when the user wants to hand off the generated color theme to a designer or connect the agent to a Figma file.
version: 1.0.0
---

# Figma Output Skill

## Two modes

### 1. tokens.json (always runs)

The agent always writes `tokens.json` in W3C DTCG format (Design Token Community Group). This file is compatible with:
- **Style Dictionary** — transform to CSS, iOS, Android, JSON
- **Token Pipeline** — Figma Tokens Plugin compatible
- **sd-transforms** — direct Tailwind config generation
- Any tool that reads the `$value` / `$type` format

Example output:
```json
{
  "$metadata": {
    "theme": "Modern Bold",
    "personality": "Clean Minimal",
    "generatedAt": "2026-05-01T12:00:00Z"
  },
  "color": {
    "primary": { "$value": "#1a56db", "$type": "color", "$description": "Primary brand color" },
    "primary-fg": { "$value": "#ffffff", "$type": "color", "$description": "Text on primary" }
  }
}
```

### 2. Figma MCP write (requires setup)

If `FIGMA_FILE_KEY` is set, the agent calls Claude with the Figma MCP server active to write color variables directly to the Figma file.

**Prerequisites:**
1. Figma MCP server configured in your Claude Code MCP settings
2. `FIGMA_FILE_KEY` set to the key from the Figma file URL (the part after `figma.com/file/`)
3. Valid Figma access token in the MCP server config

**What gets written:**
- A variable collection named `UX Agent — {theme name}` in the Figma file
- All 11 palette tokens as Figma color variables
- Updates existing collection if it already exists

## Setup (Figma MCP)

Add to your Claude Code MCP configuration:
```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "@figma/mcp-server"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "your-figma-personal-access-token"
      }
    }
  }
}
```

Then run with the file key:
```bash
FIGMA_FILE_KEY="AbCdEfGhIjKl" \
APP_BASE_URL="https://myapp.example.com" \
UX_AGENT_ROUTES="/" \
bun run src/cli-full.ts
```

## Without Figma MCP

The `tokens.json` is the primary artifact. Import it into Figma manually using:
- Figma Tokens Plugin (free) — load JSON directly
- Variables import via Figma REST API
- Copy-paste hex values from the comparison board

## Relationship to the polish loop

The Figma output is a design handoff artifact, not a feedback loop input. The agent does not read from Figma — it writes to it. The audit-and-patch loop operates on the live rendered page (screenshots), independent of any Figma source of truth.

To close the loop: apply the CSS variables from `tokens.json` to your codebase, then re-run the agent to verify the rendered output matches the intended theme.
