---
sidebar_position: 2
title: Model Tiers
description: Strategic model assignment for optimal performance
---

# Model Tiers

Prima Delivery uses a three-tier model strategy for optimal performance and cost.

## Tier Overview

| Tier | Model | Agents | Use Case |
|------|-------|--------|----------|
| **Tier 1** | Opus | 42 | Critical architecture, security, code review |
| **Tier 2** | Sonnet | 48 | Complex development, debugging, documentation |
| **Tier 3** | Haiku | 18 | Fast operations, SEO, deployment |

## Opus Tier

<span className="model-badge model-badge--opus">Opus</span>

**Best for:** Critical decisions requiring deep reasoning

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

## Sonnet Tier

<span className="model-badge model-badge--sonnet">Sonnet</span>

**Best for:** Balanced performance for development tasks

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

## Haiku Tier

<span className="model-badge model-badge--haiku">Haiku</span>

**Best for:** Fast, routine operations

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

## Cost Considerations

| Model | Input | Output | Best For |
|-------|-------|--------|----------|
| Opus | $15/M | $75/M | Critical, complex tasks |
| Sonnet | $3/M | $15/M | Development, debugging |
| Haiku | $0.25/M | $1.25/M | High-volume, simple tasks |

### Optimization Tips

1. **Use Haiku** for routine tasks
2. **Reserve Opus** for critical decisions
3. **Default to Sonnet** for development
4. **Batch operations** to reduce API calls

## Orchestration Patterns

### Planning → Execution

```
Opus: backend-architect (design)
  ↓
Sonnet: python-pro (implement)
  ↓
Haiku: deployment-engineer (deploy)
```

### Reasoning → Action

```
Opus: incident-responder (diagnose)
  ↓
Sonnet: debugger (fix)
  ↓
Haiku: deployment-engineer (deploy)
```

### Review Pipeline

```
Sonnet: code-reviewer (initial review)
  ↓
Opus: security-auditor (security review)
  ↓
Opus: architect-reviewer (architecture review)
```

## Customizing Model Assignments

Override model assignments in agent definitions:

```yaml
---
description: My custom agent
model: anthropic/claude-opus-4-5  # Force Opus
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
