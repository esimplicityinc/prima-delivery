# Copilot Functional Improvement Suggestions

> This document captures planned functional improvements to make GitHub Copilot a fully supported first-class platform in Prima Delivery's build system and tooling.

## Current State

The build pipeline currently produces output for:
- **OpenCode** — `.opencode/agents/`, `.opencode/skills/`, `opencode.json`
- **OpenPackage** — `openpackage.yml` manifests for cross-platform distribution via `opkg`

Copilot has **zero build output** today. The `.github/` directory contains only CI workflows and contribution guidelines — no agent files, no custom instructions, no Copilot-specific configuration.

---

## Proposed Improvements

### 1. Generate `.github/copilot-instructions.md`

**Priority: High**

Add a build step that synthesizes a Copilot custom instructions file from the agent and skill corpus. This is the primary mechanism for customizing Copilot behavior per-repository.

The generated file should:
- Provide an overview of available agents and their specializations
- Include project-level coding standards and conventions
- Reference the agent files in `.github/agents/` for detailed capabilities
- Be regenerated on every build to stay in sync with agent definitions

### 2. Create `convert-copilot.ts` Script

**Priority: High**

Build a dedicated conversion script that transforms agent definitions from plugin source format to Copilot-compatible format:

- **Input:** `plugins/{plugin}/agents/*.md` (YAML frontmatter + markdown prompt)
- **Output:** `.github/agents/*.md` (plain markdown, no YAML frontmatter)
- **Transformation:**
  - Strip YAML frontmatter (Copilot doesn't support it)
  - Preserve prompt content verbatim
  - Optionally prepend agent metadata as markdown headers
  - Handle model tier references in prompt content

### 3. Add Copilot Step to Build Pipeline

**Priority: High**

Extend `scripts/build.ts` with a new build step:

```
Step 1: Convert agents (plugins → OpenCode)        [existing]
Step 2: Convert skills (plugins → OpenCode)         [existing]
Step 3: Generate opencode.json                      [existing]
Step 4: Convert agents (plugins → Copilot)          [NEW]
Step 5: Generate copilot-instructions.md            [NEW]
Step 6: Build OpenPackage manifests                 [existing]
```

### 4. Copilot Extensions Integration

**Priority: Medium**

Investigate GitHub Copilot Extensions API for deeper integration:

- Can agents be exposed as Copilot Extensions for direct `@agent-name` invocation?
- What's the registration process for custom extensions?
- Can we auto-generate extension manifests from agent definitions?
- How do extensions interact with the custom instructions file?

### 5. Add Copilot to OpenPackage Platform List

**Priority: Medium**

Ensure the OpenPackage distribution system recognizes Copilot as a target platform:

- Add `copilot` to the platform list in `openpackage.yml`
- Verify `opkg install` generates `.github/copilot-instructions.md` and `.github/agents/` for Copilot users
- Add Copilot-specific metadata to plugin manifests where needed

### 6. Copilot Frontmatter Support

**Priority: Medium**

Add a `copilot:` key to the `openpackage` frontmatter schema for platform-specific agent overrides:

```yaml
openpackage:
  copilot:
    mode: agent
    instructions_format: markdown
  opencode:
    mode: subagent
    model: medium
```

This allows agent authors to customize behavior specifically for Copilot (e.g., different prompting strategies that work better with Copilot's model).

### 7. Cursor Parity (Related)

**Priority: Low**

Similar functional gaps exist for Cursor:

- No `.cursorrules` generation in the build pipeline
- No `convert-cursor.ts` script
- `.cursor/agents/` and `.cursor/skills/` directories not generated

The Copilot build infrastructure can serve as a template for adding Cursor support.

---

## Implementation Order

1. `convert-copilot.ts` — Foundation for all other work
2. Build pipeline integration — Wire the new script into `build.ts`
3. `copilot-instructions.md` generation — The user-facing output
4. OpenPackage integration — Distribution support
5. Frontmatter schema — Author customization
6. Extensions investigation — Advanced integration

---

## Success Criteria

- [ ] `bun run build` generates `.github/copilot-instructions.md`
- [ ] `bun run build` generates `.github/agents/*.md` for all 108 agents
- [ ] Copilot agent files contain no YAML frontmatter
- [ ] `copilot-instructions.md` lists all available agents with descriptions
- [ ] OpenPackage `opkg install` works for Copilot users
- [ ] All agent prompt content is preserved during conversion
- [ ] Build validates Copilot output alongside OpenCode output
