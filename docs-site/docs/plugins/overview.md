---
sidebar_position: 1
title: Plugin Catalog
description: Browse all 72 plugins organized by category
---

# Plugin Catalog

Prima Delivery includes **72 focused, single-purpose plugins** for Claude Code.

## Quick Start - Essential Plugins

### Development Essentials

```bash
/plugin install python-development      # Python with 5 skills
/plugin install javascript-typescript   # JS/TS with 4 skills
/plugin install backend-development     # APIs with 3 skills
```

### Infrastructure

```bash
/plugin install kubernetes-operations   # K8s with 4 skills
/plugin install cloud-infrastructure    # Cloud with 4 skills
/plugin install cicd-automation         # CI/CD with 4 skills
```

### Quality

```bash
/plugin install security-scanning       # Security with SAST
/plugin install code-review-ai          # AI-powered review
/plugin install unit-testing            # Test generation
```

## Plugins by Category

### Development (4 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `debugging-toolkit` | 2 | - | Smart debugging and DX |
| `backend-development` | 4 | 9 | API design and architecture |
| `frontend-mobile-development` | 1 | - | UI and mobile development |
| `multi-platform-apps` | 5 | - | Cross-platform apps |

### Languages (7 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `python-development` | 3 | 16 | Python ecosystem |
| `javascript-typescript` | 2 | 4 | JS/TS development |
| `systems-programming` | 4 | - | Rust, Go, C, C++ |
| `jvm-languages` | 3 | - | Java, Scala, C# |
| `web-scripting` | 2 | - | PHP, Ruby |
| `functional-programming` | 2 | - | Elixir, Haskell |
| `arm-cortex-microcontrollers` | 1 | - | Embedded ARM |

### Infrastructure (5 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `deployment-strategies` | 2 | - | Deployment patterns |
| `deployment-validation` | 1 | - | Config validation |
| `kubernetes-operations` | 1 | 4 | K8s and GitOps |
| `cloud-infrastructure` | 4 | 8 | AWS/Azure/GCP |
| `cicd-automation` | 5 | 4 | Pipeline automation |

### Security (4 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `security-scanning` | 2 | 5 | SAST and scanning |
| `security-compliance` | 1 | - | SOC2/HIPAA/GDPR |
| `backend-api-security` | 2 | - | API security |
| `frontend-mobile-security` | 2 | - | Client-side security |

### Testing & Quality (5 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `unit-testing` | 2 | - | Test generation |
| `tdd-workflows` | 2 | - | TDD methodology |
| `code-review-ai` | 1 | - | AI code review |
| `comprehensive-review` | 3 | - | Multi-perspective review |
| `performance-testing-review` | 2 | - | Performance analysis |

### AI & ML (4 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `llm-application-dev` | 3 | 8 | LLM applications |
| `agent-orchestration` | 1 | - | Multi-agent systems |
| `context-management` | 1 | - | Context handling |
| `machine-learning-ops` | 3 | 1 | MLOps pipelines |

### Data (2 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `data-engineering` | 1 | 5 | ETL and pipelines |
| `data-validation-suite` | 1 | - | Data quality |

### Database (3 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `database-design` | 2 | - | Schema design |
| `database-migrations` | 2 | - | Migration strategies |
| `database-cloud-optimization` | 1 | - | Performance tuning |

### Operations (4 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `incident-response` | 2 | - | Incident management |
| `error-diagnostics` | 2 | - | Error analysis |
| `distributed-debugging` | 1 | - | Distributed tracing |
| `observability-monitoring` | 3 | - | Monitoring and SLOs |

### Documentation (4 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `code-documentation` | 2 | - | Doc generation |
| `documentation-generation` | 2 | - | API docs |
| `c4-architecture` | 4 | - | Architecture diagrams |
| `api-scaffolding` | 2 | - | API templates |

### Business & Marketing (7 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `business-analytics` | 1 | 2 | Metrics and KPIs |
| `hr-legal-compliance` | 2 | - | HR and legal |
| `customer-sales-automation` | 2 | - | Sales automation |
| `seo-content-creation` | 3 | - | SEO content |
| `seo-technical-optimization` | 4 | - | Technical SEO |
| `seo-analysis-monitoring` | 3 | - | SEO analysis |
| `content-marketing` | 2 | - | Content strategy |

### Specialized (6 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `blockchain-web3` | 1 | 4 | Smart contracts |
| `quantitative-trading` | 2 | - | Trading strategies |
| `payment-processing` | 1 | 4 | Payment integration |
| `game-development` | 2 | 2 | Unity, Godot |
| `accessibility-compliance` | 2 | - | WCAG compliance |
| `framework-migration` | 1 | 4 | Legacy modernization |

### Workflows (4 plugins)

| Plugin | Agents | Skills | Description |
|--------|--------|--------|-------------|
| `conductor` | 1 | 3 | Context-driven development |
| `git-pr-workflows` | 1 | - | Git automation |
| `full-stack-orchestration` | 1 | - | Multi-agent workflows |
| `code-refactoring` | 2 | - | Refactoring tools |

## Installation

### Add Marketplace

```bash
/plugin marketplace add prima-delivery
```

### Install Plugin

```bash
/plugin install [plugin-name]
```

### List Installed

```bash
/plugin list
```

### Uninstall

```bash
/plugin uninstall [plugin-name]
```

## Plugin Structure

Each plugin contains:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json       # Metadata
├── agents/               # Bundled agents
├── commands/             # Slash commands
└── skills/               # Bundled skills
```

## Next Steps

- [Agent Overview](/docs/agents/overview) - Browse all agents
- [Skills Overview](/docs/skills/overview) - Browse all skills
- [Usage Guide](/docs/usage/commands) - Command reference
