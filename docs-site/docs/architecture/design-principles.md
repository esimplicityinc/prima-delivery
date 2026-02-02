---
sidebar_position: 1
title: Design Principles
description: Core architecture and design philosophy of Prima Delivery
---

# Design Principles

The core philosophy behind Prima Delivery's architecture.

## Single Responsibility

Each component does **one thing well**:

- **Agents** - Specialized domain expertise
- **Skills** - Modular knowledge packages
- **Plugins** - Focused workflow bundles

### Benefits

- Clear, focused purposes
- Minimal token usage
- Easier maintenance
- Better composability

## Composability Over Bundling

Mix and match components based on needs:

```
# Combine agents for complex tasks
@backend-architect + @database-architect + @security-auditor

# Layer skills for deep expertise
api-design-principles + microservices-patterns + security-patterns
```

### Benefits

- Install only what you need
- No forced feature bundling
- Clear boundaries
- Flexible workflows

## Progressive Disclosure

Skills follow a three-tier architecture:

```
┌─────────────────────────────────────┐
│  Tier 1: Metadata                   │  ← Always loaded
│  - Name, description                │
│  - Activation triggers              │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Tier 2: Instructions               │  ← Loaded when activated
│  - Core guidance                    │
│  - Key patterns                     │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Tier 3: Resources                  │  ← Loaded on demand
│  - Examples                         │
│  - Templates                        │
│  - References                       │
└─────────────────────────────────────┘
```

### Benefits

- Efficient token usage
- Contextual knowledge loading
- Reduced noise

## Context Efficiency

Smaller, focused components = better results:

| Approach | Tokens | Accuracy |
|----------|--------|----------|
| Monolithic prompt | High | Lower |
| Focused agent | Low | Higher |
| Agent + relevant skills | Optimal | Highest |

### Principles

1. Load only relevant knowledge
2. Use appropriate model tier
3. Combine specialists for complex tasks

## Maintainability

Clear boundaries enable:

- **Isolated updates** - Change one component without affecting others
- **Easy testing** - Test components independently
- **Clear ownership** - Each component has defined scope
- **Version control** - Track changes per component

## Dual Platform Support

Prima Delivery supports both OpenCode and Claude Code:

| Feature | OpenCode | Claude Code |
|---------|----------|-------------|
| Agents | `.opencode/agents/` | Plugin bundles |
| Skills | `.opencode/skills/` | Plugin bundles |
| Config | `opencode.json` | `marketplace.json` |
| Invoke | `@agent-name` | Natural language |

## Statistics

| Component | Count | Avg. Size |
|-----------|-------|-----------|
| Agents | 108 | ~2KB |
| Skills | 140 | ~5KB |
| Plugins | 72 | ~3 components |

## Next Steps

- [Model Tiers](/docs/architecture/model-tiers) - Agent model assignments
- [Repository Structure](/docs/architecture/repository-structure) - File organization
