---
sidebar_position: 3
title: Skill Format
description: Specification for skill definition files
---

# Skill Format Specification

Complete specification for Prima Delivery skill packages.

## Directory Structure

```
.opencode/skills/{skill-name}/
├── SKILL.md              # Required: Main definition
├── references/           # Optional: Reference documents
│   └── *.md
├── assets/               # Optional: Templates, configs
│   └── *.*
└── scripts/              # Optional: Helper scripts
    └── *.sh
```

## Naming Convention

Skill directory names should be:
- Lowercase
- Hyphen-separated
- 1-64 characters
- Alphanumeric with hyphens only

Examples:
- `async-python-patterns`
- `kubernetes-manifest-generator`
- `api-design-principles`

## SKILL.md Format

```markdown
---
name: skill-name
description: Description including "Use when..." triggers
---

# Skill Title

## When to Use

- Trigger condition 1
- Trigger condition 2

## Core Content

[Main skill instructions and knowledge]

## Examples

[Code examples and patterns]

## Best Practices

[Guidelines and recommendations]
```

## Frontmatter Fields

### name (required)

Unique identifier matching the directory name.

```yaml
name: async-python-patterns
```

**Constraints:**
- Must match directory name
- 1-64 characters
- Lowercase alphanumeric with hyphens

### description (required)

Description including activation triggers.

```yaml
description: Master Python asyncio and concurrent programming. Use when building async APIs, concurrent systems, or I/O-bound applications.
```

**Guidelines:**
- Include "Use when..." clause
- Keep under 500 characters
- Be specific about activation scenarios

## Content Sections

### When to Use

List specific activation triggers:

```markdown
## When to Use

- Building async web APIs (FastAPI, aiohttp)
- Implementing concurrent I/O operations
- Creating real-time applications
- Processing multiple independent tasks
```

### Core Content

Main skill knowledge and instructions:

```markdown
## Core Concepts

### Event Loop
The event loop manages async tasks...

### Coroutines
Functions defined with `async def`...

### Tasks
Scheduled coroutines that run concurrently...
```

### Examples

Code examples demonstrating patterns:

```markdown
## Examples

### Basic Async Function

\`\`\`python
async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()
\`\`\`
```

### Best Practices

Guidelines for applying the skill:

```markdown
## Best Practices

1. **Use async context managers** for resource cleanup
2. **Avoid blocking calls** in async functions
3. **Use gather()** for concurrent operations
4. **Handle exceptions** in task groups
```

## Supporting Files

### References

Additional documentation in `references/`:

```markdown
<!-- references/advanced-patterns.md -->
# Advanced Async Patterns

## Semaphores
Control concurrent access...

## Task Groups
Manage related tasks...
```

### Assets

Templates and configurations in `assets/`:

```yaml
# assets/config-template.yaml
async:
  max_connections: 100
  timeout: 30
```

### Scripts

Helper scripts in `scripts/`:

```bash
#!/bin/bash
# scripts/validate.sh
python -m py_compile "$1"
```

## Complete Example

```
async-python-patterns/
├── SKILL.md
├── references/
│   ├── concurrency-patterns.md
│   └── error-handling.md
└── assets/
    └── async-template.py
```

**SKILL.md:**

```markdown
---
name: async-python-patterns
description: Master Python asyncio and concurrent programming. Use when building async APIs, concurrent systems, or I/O-bound applications requiring non-blocking operations.
---

# Async Python Patterns

## When to Use

- Building async web APIs (FastAPI, aiohttp)
- Implementing concurrent I/O operations
- Creating real-time applications
- Processing multiple independent tasks

## Core Concepts

### Event Loop

The event loop is the heart of asyncio...

[Continue with full content]
```

## Validation

Skills are validated for:

- Directory name matches `name` field
- `name` follows naming conventions
- `description` includes activation triggers
- `description` is under 1024 characters
- `SKILL.md` exists in directory

## Next Steps

- [Agent Format](/docs/api/agent-format) - Agent specification
- [Scripts Reference](/docs/api/scripts) - Build scripts
