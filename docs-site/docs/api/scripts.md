---
sidebar_position: 4
title: Scripts Reference
description: Build and generation scripts API
---

# Scripts Reference

Documentation for Prima Delivery build and generation scripts.

## Available Scripts

### Main Build

```bash
npm run build
# or
bun run scripts/build.ts
```

Orchestrates the complete build process:
1. Converts agents to OpenCode format
2. Validates and copies skills
3. Generates `opencode.json`

### Convert Agents

```bash
npm run convert:agents
# or
bun run scripts/convert-agents.ts
```

Converts agent files from source format to OpenCode format.

**Operations:**
- Parse YAML frontmatter
- Map model names to full provider/model IDs
- Validate required fields
- Output to `.opencode/agents/`

### Convert Skills

```bash
npm run convert:skills
# or
bun run scripts/convert-skills.ts
```

Validates and processes skill files.

**Operations:**
- Validate skill name format
- Validate description length
- Check directory structure
- Copy to `.opencode/skills/`

### Validate Only

```bash
npm run validate
# or
bun run scripts/convert-skills.ts --validate
```

Validates skills without copying files.

## Documentation Generation

### Generate All Docs

```bash
cd docs-site
npm run generate
```

Generates all documentation pages from source files.

### Generate Agent Docs

```bash
npx ts-node scripts/generate-agent-docs.ts
```

**Input:** `../.opencode/agents/*.md`
**Output:** `docs/agents/{category}/{agent}.md`

**Operations:**
1. Read all agent files
2. Parse YAML frontmatter
3. Categorize by keywords
4. Generate Docusaurus-compatible markdown
5. Create category indices

### Generate Skill Docs

```bash
npx ts-node scripts/generate-skill-docs.ts
```

**Input:** `../.opencode/skills/*/SKILL.md`
**Output:** `docs/skills/{category}/{skill}.md`

**Operations:**
1. Read all skill directories
2. Parse SKILL.md files
3. Categorize by keywords
4. Generate Docusaurus-compatible markdown
5. Create category indices

## Script Configuration

### Environment Variables

```bash
# Enable debug output
DEBUG=true npm run build

# Specify output directory
OUTPUT_DIR=/custom/path npm run convert:agents
```

### Script Options

```typescript
// scripts/convert-agents.ts
interface Options {
  inputDir: string;    // Source directory
  outputDir: string;   // Output directory
  validate: boolean;   // Validate only, don't write
  verbose: boolean;    // Enable verbose logging
}
```

## Model Mapping

Agents with short model names are mapped to full IDs:

| Short | Full ID |
|-------|---------|
| `opus` | `anthropic/claude-opus-4-5` |
| `sonnet` | `anthropic/claude-sonnet-4-20250514` |
| `haiku` | `anthropic/claude-haiku-4-20250514` |
| `inherit` | (omitted - uses session default) |

## Category Rules

Agents and skills are auto-categorized based on keywords:

```typescript
const categoryRules = [
  { pattern: /python|django|fastapi/i, category: 'languages/python' },
  { pattern: /typescript|javascript/i, category: 'languages/javascript' },
  { pattern: /kubernetes|k8s|terraform/i, category: 'infrastructure' },
  { pattern: /security|threat|audit/i, category: 'security' },
  // ... more rules
];
```

## Output Formats

### Agent Page

```markdown
---
sidebar_label: Agent Name
title: Agent Name
description: Agent description
tags: [category, model-tier]
---

# Agent Name

<span className="model-badge">Model</span>

[Description]

## Overview
[Content]

## Usage
[Examples]
```

### Skill Page

```markdown
---
sidebar_label: Skill Name
title: Skill Name
description: Skill description
tags: [category, skill]
---

# Skill Name

[Description]

## When to Use
[Triggers]

[Content]
```

## Extending Scripts

### Adding Categories

Edit category rules in generation scripts:

```typescript
// scripts/generate-agent-docs.ts
const categoryRules = [
  // Add new category
  { pattern: /my-keyword/i, category: 'my-category' },
  // ... existing rules
];
```

### Custom Processing

Create custom scripts using the same patterns:

```typescript
import * as fs from 'fs';
import * as path from 'path';

function parseFrontmatter(content: string) {
  // Parse YAML frontmatter
}

function processFile(filePath: string) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const { frontmatter, body } = parseFrontmatter(content);
  // Custom processing
}
```

## Next Steps

- [Agent Format](/docs/api/agent-format) - Agent specification
- [Skill Format](/docs/api/skill-format) - Skill specification
