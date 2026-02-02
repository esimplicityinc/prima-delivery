/**
 * Generate Skill Documentation Pages
 * 
 * Reads skill definitions from ../.opencode/skills/ and generates
 * Docusaurus-compatible markdown files in docs/skills/
 */

import * as fs from 'fs';
import * as path from 'path';

interface SkillFrontmatter {
  name: string;
  description: string;
}

interface Skill {
  name: string;
  slug: string;
  frontmatter: SkillFrontmatter;
  content: string;
  category: string;
}

// Category mapping based on keywords in skill name/description
const categoryRules: Array<{ pattern: RegExp; category: string }> = [
  // Python
  { pattern: /python|django|fastapi|pydantic|pytest|asyncio|uv-package/i, category: 'python' },
  
  // JavaScript/TypeScript
  { pattern: /typescript|javascript|nodejs|react|nextjs|angular|tailwind/i, category: 'javascript' },
  
  // Rust/Go/Systems
  { pattern: /rust|golang|go-|memory-safety/i, category: 'systems' },
  
  // Infrastructure
  { pattern: /kubernetes|k8s|helm|terraform|cloud|aws|azure|gcp|gitops|istio|linkerd/i, category: 'infrastructure' },
  { pattern: /deployment|cicd|github-actions|gitlab|secrets/i, category: 'cicd' },
  
  // Database
  { pattern: /database|sql|postgresql|migration/i, category: 'database' },
  
  // Security
  { pattern: /security|sast|threat|stride|attack|pci|gdpr/i, category: 'security' },
  
  // Testing & Quality
  { pattern: /test|e2e|bats|debugging/i, category: 'testing' },
  { pattern: /code-review|error-handling/i, category: 'quality' },
  
  // AI/ML/LLM
  { pattern: /llm|langchain|rag|embedding|vector|prompt|similarity|hybrid-search/i, category: 'ai-ml' },
  { pattern: /ml-pipeline/i, category: 'ai-ml' },
  
  // Backend
  { pattern: /api-design|architecture-pattern|microservices|workflow|temporal|event|cqrs|saga|projection/i, category: 'backend' },
  { pattern: /auth-implementation/i, category: 'backend' },
  
  // Frontend/Mobile
  { pattern: /mobile|ios|android|react-native|flutter|responsive|design-system|visual-design|interaction/i, category: 'frontend' },
  { pattern: /accessibility|wcag|screen-reader/i, category: 'accessibility' },
  
  // Documentation
  { pattern: /openapi|changelog|adr|architecture-decision/i, category: 'documentation' },
  
  // Observability
  { pattern: /observability|prometheus|grafana|tracing|slo|incident|postmortem|on-call/i, category: 'observability' },
  
  // Data
  { pattern: /data-quality|dbt|spark|airflow|data-storytelling|kpi/i, category: 'data' },
  
  // Business
  { pattern: /market|startup|financial|competitive|team-composition/i, category: 'business' },
  { pattern: /employment|hr/i, category: 'hr-legal' },
  
  // Blockchain
  { pattern: /blockchain|defi|nft|solidity|web3/i, category: 'blockchain' },
  
  // Finance
  { pattern: /backtesting|risk-metrics|trading/i, category: 'finance' },
  
  // Payments
  { pattern: /stripe|paypal|payment|billing/i, category: 'payments' },
  
  // Gaming
  { pattern: /unity|godot|game/i, category: 'gaming' },
  
  // Reverse Engineering
  { pattern: /binary|memory-forensics|protocol-reverse|anti-reversing/i, category: 'reverse-engineering' },
  
  // Monorepo
  { pattern: /monorepo|nx-workspace|turborepo|bazel/i, category: 'monorepo' },
  
  // Git
  { pattern: /git-advanced/i, category: 'git' },
  
  // .NET
  { pattern: /dotnet/i, category: 'dotnet' },
];

function parseFrontmatter(content: string): { frontmatter: SkillFrontmatter; body: string } {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  
  if (!match) {
    return {
      frontmatter: { name: '', description: '' },
      body: content,
    };
  }

  const yamlContent = match[1];
  const body = match[2];

  const frontmatter: SkillFrontmatter = { name: '', description: '' };
  
  // Parse name
  const nameMatch = yamlContent.match(/name:\s*([^\n]+)/);
  if (nameMatch) {
    frontmatter.name = nameMatch[1].trim();
  }

  // Parse description (may be multiline)
  const descMatch = yamlContent.match(/description:\s*([^\n]+(?:\n\s+[^\n]+)*)/);
  if (descMatch) {
    frontmatter.description = descMatch[1]
      .split('\n')
      .map(line => line.trim())
      .join(' ')
      .trim();
  }

  return { frontmatter, body };
}

function categorizeSkill(name: string, description: string): string {
  const combined = `${name} ${description}`.toLowerCase();
  
  for (const rule of categoryRules) {
    if (rule.pattern.test(combined)) {
      return rule.category;
    }
  }
  
  return 'other';
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

function extractUseTriggers(content: string): string[] {
  const triggers: string[] = [];
  
  // Look for "Use when" or "When to Use" sections
  const whenMatch = content.match(/(?:use when|when to use)[:\s]*\n((?:[-*]\s+[^\n]+\n?)+)/i);
  if (whenMatch) {
    const lines = whenMatch[1].split('\n').filter(l => l.trim());
    for (const line of lines.slice(0, 5)) { // Max 5 triggers
      const cleaned = line.replace(/^[-*]\s+/, '').trim();
      if (cleaned) triggers.push(cleaned);
    }
  }
  
  return triggers;
}

function generateSkillPage(skill: Skill): string {
  const title = slugToTitle(skill.name);
  const triggers = extractUseTriggers(skill.content);
  const escapedDescription = escapeYamlString(skill.frontmatter.description.slice(0, 160));
  const escapedContent = escapeMarkdownContent(skill.content);
  const escapedFullDescription = escapeMarkdownContent(skill.frontmatter.description);
  
  const triggerSection = triggers.length > 0 
    ? `## When to Use\n\n${triggers.map(t => `- ${escapeMarkdownContent(t)}`).join('\n')}\n\n`
    : '';

  return `---
sidebar_label: ${title}
title: ${title}
description: ${escapedDescription}
tags: [${skill.category}, skill]
---

# ${title}

${escapedFullDescription}

${triggerSection}${escapedContent}

---

*Category: ${slugToTitle(skill.category)}*
`;
}

function getCategoryPosition(category: string): number {
  const positions: Record<string, number> = {
    'python': 1,
    'javascript': 2,
    'systems': 3,
    'dotnet': 4,
    'backend': 5,
    'frontend': 6,
    'accessibility': 7,
    'infrastructure': 8,
    'cicd': 9,
    'database': 10,
    'testing': 11,
    'quality': 12,
    'security': 13,
    'ai-ml': 14,
    'observability': 15,
    'data': 16,
    'documentation': 17,
    'monorepo': 18,
    'git': 19,
    'blockchain': 20,
    'finance': 21,
    'payments': 22,
    'gaming': 23,
    'business': 24,
    'hr-legal': 25,
    'reverse-engineering': 26,
    'other': 99,
  };
  return positions[category] || 50;
}

function generateOverview(skills: Skill[], byCategory: Record<string, Skill[]>): string {
  const categoryStats = Object.entries(byCategory)
    .sort((a, b) => getCategoryPosition(a[0]) - getCategoryPosition(b[0]))
    .map(([category, categorySkills]) => {
      const label = slugToTitle(category);
      return `| [${label}](./${category}) | ${categorySkills.length} |`;
    })
    .join('\n');

  return `---
sidebar_position: 1
title: Skills Overview
description: Complete reference for all ${skills.length} specialized skills
---

# Skills Overview

Prima Delivery includes **${skills.length} specialized skills** that extend AI capabilities with domain-specific knowledge.

## What Are Skills?

Skills are modular knowledge packages that provide:

- **Specialized Expertise**: Deep knowledge in specific domains
- **Progressive Disclosure**: Load detailed knowledge only when needed
- **Activation Triggers**: Clear "Use when..." criteria for automatic invocation

## Categories

| Category | Skills |
|----------|--------|
${categoryStats}

## How Skills Work

Skills follow a three-tier architecture:

1. **Metadata** - Name and activation criteria (always loaded)
2. **Instructions** - Core guidance (loaded when activated)  
3. **Resources** - Examples and templates (loaded on demand)

## Activation

Skills activate automatically when:

- You mention a skill by name
- Your request matches a skill's "Use when..." triggers
- An agent determines skill knowledge is needed

## Browse All Skills

Use the sidebar to browse skills by category, or use search to find a specific skill.
`;
}

async function main() {
  const skillsDir = path.resolve(__dirname, '../../.opencode/skills');
  const outputDir = path.resolve(__dirname, '../docs/skills');

  // Read all skill directories
  const skillDirs = fs.readdirSync(skillsDir).filter(f => {
    const stat = fs.statSync(path.join(skillsDir, f));
    return stat.isDirectory();
  });
  
  console.log(`Found ${skillDirs.length} skill directories`);

  const skills: Skill[] = [];

  for (const dir of skillDirs) {
    const skillPath = path.join(skillsDir, dir, 'SKILL.md');
    
    if (!fs.existsSync(skillPath)) {
      console.warn(`No SKILL.md in ${dir}, skipping`);
      continue;
    }

    const content = fs.readFileSync(skillPath, 'utf-8');
    const { frontmatter, body } = parseFrontmatter(content);
    
    const name = frontmatter.name || dir;
    const category = categorizeSkill(name, frontmatter.description);

    skills.push({
      name,
      slug: dir,
      frontmatter,
      content: body.trim(),
      category,
    });
  }

  // Group skills by category
  const byCategory: Record<string, Skill[]> = {};
  for (const skill of skills) {
    if (!byCategory[skill.category]) {
      byCategory[skill.category] = [];
    }
    byCategory[skill.category].push(skill);
  }

  // Create output directories and generate files
  for (const [category, categorySkills] of Object.entries(byCategory)) {
    const categoryDir = path.join(outputDir, category);
    fs.mkdirSync(categoryDir, { recursive: true });

    // Generate individual skill pages
    for (const skill of categorySkills) {
      const outputPath = path.join(categoryDir, `${skill.slug}.md`);
      fs.writeFileSync(outputPath, generateSkillPage(skill));
    }

    // Generate category metadata
    const indexPath = path.join(categoryDir, '_category_.json');
    const categoryLabel = slugToTitle(category);
    fs.writeFileSync(indexPath, JSON.stringify({
      label: categoryLabel,
      position: getCategoryPosition(category),
      collapsed: true,
    }, null, 2));

    console.log(`Generated ${categorySkills.length} skills in ${category}/`);
  }

  // Generate main overview page
  const overviewPath = path.join(outputDir, 'overview.md');
  fs.writeFileSync(overviewPath, generateOverview(skills, byCategory));
  console.log('Generated skills/overview.md');

  console.log(`\nTotal: ${skills.length} skill pages generated`);
}

main().catch(console.error);
