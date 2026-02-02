---
sidebar_position: 2
title: Quick Start
description: Get productive with Prima Delivery in 5 minutes
---

# Quick Start

Get productive with Prima Delivery in under 5 minutes.

## Using Agents

### OpenCode

Mention agents with `@`:

```
@python-pro Explain this code and suggest optimizations

@backend-architect Design a REST API for a todo application

@test-automator Generate unit tests for this function
```

### Claude Code

Use natural language:

```
Use python-pro to review this code

Have backend-architect design the authentication API

Get test-automator to write tests for the UserService class
```

## Common Workflows

### Code Review

```
@code-reviewer Review this pull request for:
- Code quality issues
- Security vulnerabilities  
- Performance concerns
```

### Architecture Design

```
@backend-architect Design a microservices architecture for an e-commerce platform with:
- User service
- Product catalog
- Order management
- Payment processing
```

### Debugging

```
@debugger I'm getting this error:
[paste error message]

Help me find the root cause and fix it.
```

### Documentation

```
@docs-architect Generate comprehensive documentation for this module including:
- API reference
- Usage examples
- Architecture overview
```

## Agent Categories

### Development

| Agent | Best For |
|-------|----------|
| `@python-pro` | Python development, optimization |
| `@typescript-pro` | TypeScript/JavaScript projects |
| `@backend-architect` | API design, system architecture |
| `@frontend-developer` | React, UI components |

### Infrastructure

| Agent | Best For |
|-------|----------|
| `@kubernetes-architect` | K8s deployments, GitOps |
| `@terraform-specialist` | Infrastructure as Code |
| `@cloud-architect` | AWS/Azure/GCP design |

### Quality

| Agent | Best For |
|-------|----------|
| `@code-reviewer` | Code review, best practices |
| `@security-auditor` | Security assessment |
| `@test-automator` | Test generation |

### AI/ML

| Agent | Best For |
|-------|----------|
| `@ai-engineer` | LLM applications, RAG |
| `@ml-engineer` | ML pipelines, training |
| `@prompt-engineer` | Prompt optimization |

## Using Skills

Skills activate automatically based on your request. You can also reference them explicitly:

```
@python-pro Using the async-python-patterns skill, help me implement concurrent API calls

@backend-architect Apply the api-design-principles skill to design a RESTful API
```

## Model Tiers

Agents are assigned to optimal model tiers:

| Tier | Badge | Use Case |
|------|-------|----------|
| **Opus** | <span className="model-badge model-badge--opus">Opus</span> | Critical architecture, security |
| **Sonnet** | <span className="model-badge model-badge--sonnet">Sonnet</span> | Complex development |
| **Haiku** | <span className="model-badge model-badge--haiku">Haiku</span> | Fast operations |

## Tips for Best Results

1. **Be specific** - Provide context about your project and requirements
2. **Share code** - Include relevant code snippets for review
3. **State constraints** - Mention any limitations or requirements
4. **Ask follow-ups** - Agents maintain context for multi-turn conversations

## Next Steps

- [Browse All Agents](/docs/agents/overview) - Find the right agent for your task
- [Browse All Skills](/docs/skills/overview) - Explore available knowledge packages
- [Usage Guide](/docs/usage/commands) - Learn advanced usage patterns
