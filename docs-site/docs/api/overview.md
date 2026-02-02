---
sidebar_position: 1
title: API Overview
description: Technical reference for Prima Delivery formats and scripts
---

# API Reference

Technical specifications for Prima Delivery components.

## Component Formats

### Agents

Agents are markdown files with YAML frontmatter:

```markdown
---
description: Brief description (required)
mode: subagent | primary (optional)
model: provider/model-id (optional)
---

Agent prompt content...
```

[→ Full Agent Format Specification](/docs/api/agent-format)

### Skills

Skills are directories containing a `SKILL.md` file:

```markdown
---
name: skill-name (required)
description: Description with triggers (required)
---

# Skill Title

Skill content...
```

[→ Full Skill Format Specification](/docs/api/skill-format)

## Build Scripts

### Generate Documentation

```bash
cd docs-site
npm run generate
```

Runs:
- `generate-agent-docs.ts` - Creates agent pages
- `generate-skill-docs.ts` - Creates skill pages

### Convert Agents

```bash
npm run convert:agents
```

Converts agent files to OpenCode format.

### Validate Skills

```bash
npm run validate
```

Validates skill files against the specification.

[→ Full Scripts Reference](/docs/api/scripts)

## Directory Structure

```
prima-delivery/
├── .opencode/
│   ├── agents/     # Agent definitions
│   └── skills/     # Skill packages
├── scripts/        # Build scripts
└── docs-site/      # This documentation
```

## Integration

### OpenCode

Prima Delivery components are automatically discovered from:
- `.opencode/agents/*.md`
- `.opencode/skills/*/SKILL.md`

### Claude Code

Components are bundled into plugins defined in:
- `.claude-plugin/marketplace.json`

## Next Steps

- [Agent Format](/docs/api/agent-format) - Agent specification
- [Skill Format](/docs/api/skill-format) - Skill specification
- [Scripts Reference](/docs/api/scripts) - Build script API
