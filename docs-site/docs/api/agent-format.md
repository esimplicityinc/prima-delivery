---
sidebar_position: 2
title: Agent Format
description: Specification for agent definition files
---

# Agent Format Specification

Complete specification for Prima Delivery agent files.

## File Location

```
.opencode/agents/{agent-name}.md
```

Agent names should be:
- Lowercase
- Hyphen-separated
- Descriptive of the agent's role

## File Structure

```markdown
---
description: Brief description shown in autocomplete
mode: subagent
model: anthropic/claude-sonnet-4-20250514
---

# Agent Title (optional)

Agent prompt content defining behavior, capabilities, and guidelines...
```

## Frontmatter Fields

### description (required)

Brief description displayed in agent autocomplete.

```yaml
description: Expert Python developer with deep knowledge of async patterns and modern tooling
```

**Guidelines:**
- Keep under 200 characters
- Start with role/expertise
- Include key capabilities
- Mention when to use (e.g., "Use for...")

### mode (optional)

Agent execution mode.

```yaml
mode: subagent  # Default - runs as a sub-agent
mode: primary   # Runs as the main agent
```

| Mode | Description |
|------|-------------|
| `subagent` | Invoked by other agents or user mentions |
| `primary` | Takes over as the main conversation agent |

### model (optional)

Target model for this agent.

```yaml
model: anthropic/claude-opus-4-5
model: anthropic/claude-sonnet-4-20250514
model: anthropic/claude-haiku-4-20250514
```

If omitted, uses the session's default model.

## Prompt Content

The content after the frontmatter defines the agent's behavior.

### Structure

```markdown
---
[frontmatter]
---

You are a [role] specializing in [domain].

## Purpose

[What this agent does]

## Capabilities

### [Capability 1]
- Detail
- Detail

### [Capability 2]
- Detail
- Detail

## Guidelines

1. [Guideline 1]
2. [Guideline 2]

## Output Format

[How to structure responses]
```

### Best Practices

1. **Clear role definition** - Start with "You are a..."
2. **Specific capabilities** - List what the agent can do
3. **Guidelines** - Define behavior and constraints
4. **Output format** - Specify how to structure responses
5. **Examples** - Include sample interactions if helpful

## Complete Example

```markdown
---
description: Expert Python developer for async patterns, optimization, and modern tooling. Use for Python development and code review.
mode: subagent
model: anthropic/claude-sonnet-4-20250514
---

You are a Python expert specializing in modern Python 3.12+ development.

## Purpose

Expert Python developer mastering async patterns, performance optimization, and modern tooling including uv, ruff, and pytest.

## Capabilities

### Modern Python Features
- Async/await patterns with asyncio
- Type hints and generics
- Dataclasses and Pydantic models
- Pattern matching

### Tooling
- Package management with uv
- Code quality with ruff
- Testing with pytest

## Guidelines

1. Always use type hints
2. Prefer async for I/O operations
3. Follow PEP 8 style guidelines
4. Write comprehensive tests

## Output Format

When reviewing code:
1. Summary of findings
2. Specific issues with line numbers
3. Suggested improvements with code examples
4. Best practice recommendations
```

## Validation

Agent files are validated for:

- Valid YAML frontmatter
- Required `description` field
- Valid `mode` value (if present)
- Valid `model` format (if present)

## Next Steps

- [Skill Format](/docs/api/skill-format) - Skill specification
- [Scripts Reference](/docs/api/scripts) - Build scripts
