---
sidebar_position: 3
title: Configuration
description: Configure Prima Delivery for your workflow
---

# Configuration

Customize Prima Delivery for your specific needs.

## OpenCode Configuration

### opencode.json

The main configuration file for OpenCode:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    // Agent configurations are auto-discovered from .opencode/agents/
  }
}
```

### Agent File Format

Agents are defined in `.opencode/agents/*.md` with YAML frontmatter:

```markdown
---
description: Your agent description here
mode: subagent
model: anthropic/claude-sonnet-4-20250514
---

Your agent prompt content here...
```

#### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `description` | Yes | Brief description shown in autocomplete |
| `mode` | No | `subagent` (default) or `primary` |
| `model` | No | Model to use (defaults to session model) |

#### Model Options

```yaml
# Opus - for critical tasks
model: anthropic/claude-opus-4-5

# Sonnet - balanced performance  
model: anthropic/claude-sonnet-4-20250514

# Haiku - fast operations
model: anthropic/claude-haiku-4-20250514
```

### Skill File Format

Skills are defined in `.opencode/skills/{name}/SKILL.md`:

```markdown
---
name: my-skill-name
description: Skill description with "Use when..." trigger
---

# Skill Title

Skill content with instructions, examples, and references...
```

## Claude Code Configuration

### Plugin Structure

```
plugins/
└── my-plugin/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── agents/
    │   └── my-agent.md
    ├── commands/
    │   └── my-command.md
    └── skills/
        └── my-skill/
            └── SKILL.md
```

### plugin.json

```json
{
  "name": "my-plugin",
  "description": "Plugin description",
  "version": "1.0.0",
  "author": {
    "name": "Prima Team",
    "email": "team@esimplicity.com"
  }
}
```

## Customizing Agents

### Override an Agent

Create a file with the same name in your project's `.opencode/agents/` to override:

```markdown
---
description: My customized Python expert
mode: subagent
model: anthropic/claude-opus-4-5
---

You are a Python expert specialized in MY company's coding standards...
```

### Create a New Agent

Add a new `.md` file to `.opencode/agents/`:

```markdown
---
description: Expert in our internal framework
mode: subagent
model: anthropic/claude-sonnet-4-20250514
---

You are an expert in our internal framework with knowledge of:

- Our API conventions
- Database patterns
- Testing requirements
- Deployment procedures

## Guidelines

1. Follow our coding standards
2. Use approved libraries only
3. Include comprehensive tests
...
```

## Customizing Skills

### Add a Custom Skill

Create a new directory in `.opencode/skills/`:

```
.opencode/skills/my-custom-skill/
├── SKILL.md
└── references/
    └── examples.md
```

### SKILL.md Template

```markdown
---
name: my-custom-skill
description: Description with "Use when..." activation triggers
---

# My Custom Skill

## When to Use

- Situation 1
- Situation 2
- Situation 3

## Core Concepts

...

## Examples

...

## Best Practices

...
```

## Environment Variables

```bash
# Set default model
export OPENCODE_MODEL=anthropic/claude-sonnet-4-20250514

# Enable debug logging
export OPENCODE_DEBUG=true
```

## Project-Specific Configuration

Create a project-level config to override global settings:

```
your-project/
├── .opencode/
│   ├── agents/           # Project-specific agents
│   ├── skills/           # Project-specific skills
│   └── config.json       # Project config overrides
└── opencode.json         # Main configuration
```

## Next Steps

- [Commands Reference](/docs/usage/commands) - Available slash commands
- [Agent Format](/docs/api/agent-format) - Detailed agent specification
- [Skill Format](/docs/api/skill-format) - Detailed skill specification
