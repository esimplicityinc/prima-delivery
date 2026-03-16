---
sidebar_position: 2
title: Model Tiers
description: Provider-agnostic model tier strategy for optimal performance
---

# Model Tiers

Prima Delivery uses a **provider-agnostic, three-tier model strategy** to optimize for performance, cost, and task complexity. Instead of referencing specific model names, agents are assigned to a tier — **High**, **Medium**, or **Low** — which maps to the most capable model available at that tier from your configured AI provider.

:::tip Platform Universal
Model tiers apply consistently across all supported platforms — Copilot, OpenCode, Claude Code, Cursor, and others. The tier assignment determines agent capability regardless of which platform you use.
:::

## What Are Model Tiers?

Model tiers are an abstraction layer that decouples agent definitions from specific AI providers. This means:

- **Your agents work with any supported AI provider** without modification
- **Upgrading models** requires changing only the tier mapping, not every agent
- **Cost optimization** is built into the tier system by design
- **Task complexity** drives model selection, not vendor-specific naming

## Tier Overview

| Tier | Label | Agents | Use Case |
|------|-------|--------|----------|
| **Tier 1** | High | 42 | Critical architecture, security, code review |
| **Tier 2** | Medium | 48 | Complex development, debugging, documentation |
| **Tier 3** | Low | 18 | Fast operations, SEO, deployment |

## High Tier

<span className="model-badge model-badge--high">High</span>

**The most capable model tier.** Use for tasks requiring deep reasoning, multi-step analysis, and high-stakes decisions.

### Characteristics

- Strongest reasoning and analytical capabilities
- Best at handling ambiguity and complex trade-offs
- Highest token cost per request
- Slower response times compared to lower tiers

### Assigned Agents

- Architecture: `backend-architect`, `cloud-architect`, `kubernetes-architect`
- Security: `security-auditor`, `threat-modeling-expert`
- Code Review: `code-reviewer`, `architect-reviewer`
- Data/AI: `ai-engineer`, `ml-engineer`, `data-scientist`
- Business Critical: `hr-pro`, `legal-advisor`, `quant-analyst`

### When to Use

- System architecture decisions
- Security audits and threat modeling
- Production code review
- Complex AI/ML implementations
- Business-critical operations

## Medium Tier

<span className="model-badge model-badge--medium">Medium</span>

**Balanced performance tier.** Use for day-to-day development tasks that need solid reasoning without the cost of the highest tier.

### Characteristics

- Strong reasoning with good speed
- Excellent for code generation and debugging
- Moderate token cost — the default for most work
- Good balance of quality, speed, and cost

### Assigned Agents

- Languages: `python-pro`, `typescript-pro`, `rust-pro`, `golang-pro`
- Development: `frontend-developer`, `mobile-developer`
- Testing: `test-automator`, `tdd-orchestrator`
- Debugging: `debugger`, `error-detective`
- Documentation: `tutorial-engineer`, `api-documenter`

### When to Use

- Day-to-day development
- Test generation
- Debugging and error resolution
- Technical documentation
- Code implementation

## Low Tier

<span className="model-badge model-badge--low">Low</span>

**Fastest, most economical tier.** Use for routine, well-defined operations where speed and cost matter more than deep reasoning.

### Characteristics

- Fastest response times
- Lowest token cost per request
- Good for templated or well-defined tasks
- Ideal for high-volume operations

### Assigned Agents

- SEO: `seo-meta-optimizer`, `seo-keyword-strategist`, `seo-snippet-hunter`
- Operations: `deployment-engineer`, `sales-automator`
- Documentation: `reference-builder`, `c4-code`
- Content: `seo-content-planner`, `seo-content-refresher`

### When to Use

- Quick content generation
- Routine deployments
- SEO optimization
- Simple documentation tasks
- High-volume operations

## Cost Optimization

The tier system is designed for cost efficiency. General guidance:

| Tier | Relative Cost | Best For |
|------|--------------|----------|
| High | $$$ | Critical, complex tasks |
| Medium | $$ | Development, debugging |
| Low | $ | High-volume, simple tasks |

Actual costs depend on your AI provider and the specific models mapped to each tier.

### Optimization Tips

1. **Use Low** for routine tasks to minimize cost
2. **Reserve High** for critical decisions where quality matters most
3. **Default to Medium** for general development work
4. **Batch operations** to reduce API calls

## Orchestration Patterns

Tier-aware orchestration lets you chain agents across tiers for optimal performance:

### Planning → Execution

```
High: backend-architect (design)
  ↓
Medium: python-pro (implement)
  ↓
Low: deployment-engineer (deploy)
```

### Reasoning → Action

```
High: incident-responder (diagnose)
  ↓
Medium: debugger (fix)
  ↓
Low: deployment-engineer (deploy)
```

### Review Pipeline

```
Medium: code-reviewer (initial review)
  ↓
High: security-auditor (security review)
  ↓
High: architect-reviewer (architecture review)
```

## Customizing Model Assignments

Override model assignments in agent definitions:

```yaml
---
description: My custom agent
model: high  # Force high-tier model
---
```

Or use session default:

```yaml
---
description: My custom agent
# model: (omitted - uses session default)
---
```

## Next Steps

- [Design Principles](/docs/architecture/design-principles) - Core philosophy
- [Repository Structure](/docs/architecture/repository-structure) - File organization
