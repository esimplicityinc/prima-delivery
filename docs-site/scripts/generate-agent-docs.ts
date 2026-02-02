/**
 * Generate Agent Documentation Pages
 * 
 * Reads agent definitions from ../.opencode/agents/ and generates
 * Docusaurus-compatible markdown files in docs/agents/
 */

import * as fs from 'fs';
import * as path from 'path';

interface AgentFrontmatter {
  description: string;
  mode?: string;
  model?: string;
}

interface Agent {
  name: string;
  slug: string;
  frontmatter: AgentFrontmatter;
  content: string;
  category: string;
  modelTier: string;
}

// Category mapping based on keywords in agent name/description
const categoryRules: Array<{ pattern: RegExp; category: string }> = [
  // Architecture & Design
  { pattern: /architect|design-system|graphql/i, category: 'architecture' },
  
  // Languages
  { pattern: /python|django|fastapi/i, category: 'languages/python' },
  { pattern: /typescript|javascript|nodejs/i, category: 'languages/javascript' },
  { pattern: /rust|golang|go-pro|c-pro|cpp/i, category: 'languages/systems' },
  { pattern: /java-pro|scala|csharp|dotnet/i, category: 'languages/enterprise' },
  { pattern: /ruby|php|elixir|haskell/i, category: 'languages/other' },
  { pattern: /bash|shell|posix/i, category: 'languages/shell' },
  
  // Infrastructure
  { pattern: /kubernetes|k8s|terraform|cloud|deployment|devops|service-mesh/i, category: 'infrastructure' },
  { pattern: /database|sql|data-engineer/i, category: 'data' },
  
  // Quality & Security
  { pattern: /security|threat|audit/i, category: 'security' },
  { pattern: /test|tdd|debug|error/i, category: 'quality' },
  { pattern: /review|code-review/i, category: 'quality' },
  { pattern: /performance|observability/i, category: 'operations' },
  
  // AI & ML
  { pattern: /ai-engineer|ml|machine.?learning|llm|prompt|vector|data-scientist/i, category: 'ai-ml' },
  
  // Documentation
  { pattern: /doc|tutorial|mermaid|c4-/i, category: 'documentation' },
  
  // Business
  { pattern: /business|analyst|hr|legal|sales|customer|content|seo|marketing/i, category: 'business' },
  
  // Specialized
  { pattern: /blockchain|payment|game|unity|minecraft|quant|risk|firmware|malware|reverse/i, category: 'specialized' },
  
  // UI/UX
  { pattern: /ui|ux|frontend|mobile|ios|flutter|accessibility/i, category: 'ui-ux' },
];

function parseFrontmatter(content: string): { frontmatter: AgentFrontmatter; body: string } {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  
  if (!match) {
    return {
      frontmatter: { description: '' },
      body: content,
    };
  }

  const yamlContent = match[1];
  const body = match[2];

  // Simple YAML parsing
  const frontmatter: AgentFrontmatter = { description: '' };
  
  // Parse description (may be multiline)
  const descMatch = yamlContent.match(/description:\s*([^\n]+(?:\n\s+[^\n]+)*)/);
  if (descMatch) {
    frontmatter.description = descMatch[1]
      .split('\n')
      .map(line => line.trim())
      .join(' ')
      .trim();
  }

  // Parse mode
  const modeMatch = yamlContent.match(/mode:\s*(\w+)/);
  if (modeMatch) {
    frontmatter.mode = modeMatch[1];
  }

  // Parse model
  const modelMatch = yamlContent.match(/model:\s*([^\n]+)/);
  if (modelMatch) {
    frontmatter.model = modelMatch[1].trim();
  }

  return { frontmatter, body };
}

function categorizeAgent(name: string, description: string): string {
  const combined = `${name} ${description}`.toLowerCase();
  
  for (const rule of categoryRules) {
    if (rule.pattern.test(combined)) {
      return rule.category;
    }
  }
  
  return 'other';
}

function getModelTier(model: string | undefined): string {
  if (!model) return 'sonnet';
  
  if (model.includes('opus')) return 'opus';
  if (model.includes('haiku')) return 'haiku';
  return 'sonnet';
}

function slugToTitle(slug: string): string {
  return slug
    .split('-')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function escapeYamlString(str: string): string {
  // If the string contains special characters, wrap in quotes and escape
  if (str.includes(':') || str.includes('#') || str.includes('>') || str.includes('|') || str.includes('\n') || str.startsWith(' ') || str.startsWith('"') || str.startsWith("'")) {
    return `"${str.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`;
  }
  return str;
}

function escapeMarkdownContent(str: string): string {
  // Escape double curly braces to prevent JSX expression parsing
  // Use backtick code spans to prevent parsing
  return str.replace(/\{\{([^}]+)\}\}/g, '`{{$1}}`');
}

function generateAgentPage(agent: Agent): string {
  const title = slugToTitle(agent.name);
  const modelBadge = agent.modelTier.charAt(0).toUpperCase() + agent.modelTier.slice(1);
  const escapedDescription = escapeYamlString(agent.frontmatter.description.slice(0, 160));
  const escapedContent = escapeMarkdownContent(agent.content);
  const escapedFullDescription = escapeMarkdownContent(agent.frontmatter.description);
  
  return `---
sidebar_label: ${title}
title: ${title}
description: ${escapedDescription}
tags: [${agent.category.replace('/', '-')}, ${agent.modelTier}]
---

# ${title}

<span className="model-badge model-badge--${agent.modelTier}">${modelBadge}</span>

${escapedFullDescription}

## Overview

${escapedContent}

## Usage

### OpenCode

\`\`\`
@${agent.name} [your request here]
\`\`\`

### Claude Code

\`\`\`
Use ${agent.name} to [describe your task]
\`\`\`

---

*Model: ${agent.modelTier.charAt(0).toUpperCase() + agent.modelTier.slice(1)} | Mode: ${agent.frontmatter.mode || 'subagent'}*
`;
}

function generateCategoryIndex(category: string, agents: Agent[]): string {
  const title = slugToTitle(category.split('/').pop() || category);
  
  const agentList = agents
    .sort((a, b) => a.name.localeCompare(b.name))
    .map(agent => {
      const agentTitle = slugToTitle(agent.name);
      return `| [${agentTitle}](./${agent.name}) | ${agent.modelTier} | ${agent.frontmatter.description.slice(0, 80)}${agent.frontmatter.description.length > 80 ? '...' : ''} |`;
    })
    .join('\n');

  return `---
sidebar_label: ${title}
title: ${title} Agents
---

# ${title} Agents

${agents.length} specialized agents for ${title.toLowerCase()} tasks.

| Agent | Model | Description |
|-------|-------|-------------|
${agentList}
`;
}

async function main() {
  const agentsDir = path.resolve(__dirname, '../../.opencode/agents');
  const outputDir = path.resolve(__dirname, '../docs/agents');

  // Read all agent files
  const files = fs.readdirSync(agentsDir).filter(f => f.endsWith('.md'));
  console.log(`Found ${files.length} agent files`);

  const agents: Agent[] = [];

  for (const file of files) {
    const filePath = path.join(agentsDir, file);
    const content = fs.readFileSync(filePath, 'utf-8');
    const { frontmatter, body } = parseFrontmatter(content);
    
    const name = file.replace('.md', '');
    const category = categorizeAgent(name, frontmatter.description);
    const modelTier = getModelTier(frontmatter.model);

    agents.push({
      name,
      slug: name,
      frontmatter,
      content: body.trim(),
      category,
      modelTier,
    });
  }

  // Group agents by category
  const byCategory: Record<string, Agent[]> = {};
  for (const agent of agents) {
    if (!byCategory[agent.category]) {
      byCategory[agent.category] = [];
    }
    byCategory[agent.category].push(agent);
  }

  // Create output directories and generate files
  for (const [category, categoryAgents] of Object.entries(byCategory)) {
    const categoryDir = path.join(outputDir, category);
    fs.mkdirSync(categoryDir, { recursive: true });

    // Generate individual agent pages
    for (const agent of categoryAgents) {
      const outputPath = path.join(categoryDir, `${agent.name}.md`);
      fs.writeFileSync(outputPath, generateAgentPage(agent));
    }

    // Generate category index
    const indexPath = path.join(categoryDir, '_category_.json');
    const categoryLabel = slugToTitle(category.split('/').pop() || category);
    fs.writeFileSync(indexPath, JSON.stringify({
      label: categoryLabel,
      position: getCategoryPosition(category),
      collapsed: true,
    }, null, 2));

    console.log(`Generated ${categoryAgents.length} agents in ${category}/`);
  }

  // Generate main overview page
  const overviewPath = path.join(outputDir, 'overview.md');
  fs.writeFileSync(overviewPath, generateOverview(agents, byCategory));
  console.log('Generated agents/overview.md');

  console.log(`\nTotal: ${agents.length} agent pages generated`);
}

function getCategoryPosition(category: string): number {
  const positions: Record<string, number> = {
    'architecture': 1,
    'ui-ux': 2,
    'languages/python': 3,
    'languages/javascript': 4,
    'languages/systems': 5,
    'languages/enterprise': 6,
    'languages/shell': 7,
    'languages/other': 8,
    'infrastructure': 9,
    'data': 10,
    'quality': 11,
    'security': 12,
    'operations': 13,
    'ai-ml': 14,
    'documentation': 15,
    'business': 16,
    'specialized': 17,
    'other': 99,
  };
  return positions[category] || 50;
}

function generateOverview(agents: Agent[], byCategory: Record<string, Agent[]>): string {
  const categoryStats = Object.entries(byCategory)
    .sort((a, b) => getCategoryPosition(a[0]) - getCategoryPosition(b[0]))
    .map(([category, categoryAgents]) => {
      const label = slugToTitle(category.split('/').pop() || category);
      return `| [${label}](./${category.replace('/', '/')}) | ${categoryAgents.length} |`;
    })
    .join('\n');

  const modelStats = {
    opus: agents.filter(a => a.modelTier === 'opus').length,
    sonnet: agents.filter(a => a.modelTier === 'sonnet').length,
    haiku: agents.filter(a => a.modelTier === 'haiku').length,
  };

  return `---
sidebar_position: 1
title: Agent Overview
description: Complete reference for all ${agents.length} specialized AI agents
---

# Agent Overview

Prima Delivery includes **${agents.length} specialized AI agents** organized by domain expertise.

## Model Distribution

| Model | Count | Use Case |
|-------|-------|----------|
| <span className="model-badge model-badge--opus">Opus</span> | ${modelStats.opus} | Critical architecture, security, code review |
| <span className="model-badge model-badge--sonnet">Sonnet</span> | ${modelStats.sonnet} | Complex development, debugging |
| <span className="model-badge model-badge--haiku">Haiku</span> | ${modelStats.haiku} | Fast operations, SEO, deployment |

## Categories

| Category | Agents |
|----------|--------|
${categoryStats}

## Quick Start

### OpenCode

\`\`\`bash
# Mention any agent with @
@python-pro Help me optimize this function

@backend-architect Design a REST API for user management
\`\`\`

### Claude Code

\`\`\`
Use python-pro to review this code

Have backend-architect design the authentication system
\`\`\`

## Browse All Agents

Use the sidebar to browse agents by category, or use search to find a specific agent.
`;
}

main().catch(console.error);
