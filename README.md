<p align="center">
  <img src="prima-deliver-square-trans.png" alt="Prima Delivery" width="120" height="120">
</p>

# Prima Delivery

Internal AI development toolkit with 108 specialized agents and 140 skills for accelerated software development.

## Overview

Prima Delivery provides a comprehensive collection of AI-powered development tools organized into focused, single-purpose components:

| Component | Count | Description |
|-----------|-------|-------------|
| **Agents** | 108 | Specialized AI assistants for specific domains |
| **Skills** | 140 | Modular knowledge packages with progressive disclosure |
| **Plugins** | 72 | Workflow bundles combining agents, skills, and commands |

## Installation

### OpenCode (Recommended)

Copy the `.opencode/` directory to your project root:

```bash
cp -r .opencode/ /path/to/your/project/
```

Or install globally:

```bash
cp -r .opencode/ ~/.config/opencode/
```

**Structure:**
```
.opencode/
├── agents/     # 108 agent markdown files
├── skills/     # 140 skill directories
├── commands/   # Custom slash commands
└── plugins/    # TypeScript plugins
```

### Claude Code

Add the marketplace to your Claude Code installation:

```bash
/plugin marketplace add [internal-path]/prima-delivery
```

Install specific plugins:

```bash
/plugin install python-development
/plugin install backend-development
/plugin install security-scanning
```

## Agent Categories

### Development & Architecture
- `backend-architect` - API design, microservices, database schemas
- `frontend-developer` - React, responsive layouts, state management
- `database-architect` - Schema design, technology selection, optimization

### Programming Languages
- `python-pro`, `typescript-pro`, `golang-pro`, `rust-pro`
- `java-pro`, `csharp-pro`, `ruby-pro`, `php-pro`
- `c-pro`, `cpp-pro`, `elixir-pro`, `haskell-pro`

### Infrastructure & DevOps
- `cloud-architect` - AWS/Azure/GCP infrastructure
- `kubernetes-architect` - Container orchestration, GitOps
- `terraform-specialist` - Infrastructure as Code
- `deployment-engineer` - CI/CD pipelines

### Quality & Security
- `code-reviewer` - Code review with security focus
- `security-auditor` - Vulnerability assessment, OWASP
- `test-automator` - Unit, integration, e2e testing
- `performance-engineer` - Profiling, optimization

### Data & AI
- `ai-engineer` - LLM applications, RAG systems
- `ml-engineer` - ML pipelines, model serving
- `data-scientist` - Analysis, modeling, BigQuery
- `data-engineer` - ETL, data warehouses

### Documentation
- `docs-architect` - Technical documentation
- `api-documenter` - OpenAPI/Swagger specs
- `tutorial-engineer` - Step-by-step guides

[View complete agent reference](docs/agents.md)

## Skills

Skills provide specialized knowledge that agents can load on-demand:

### Language Skills
- `async-python-patterns` - AsyncIO, concurrency
- `typescript-advanced-types` - Generics, type inference
- `rust-ownership-patterns` - Memory safety, borrowing

### Infrastructure Skills
- `kubernetes-manifest-patterns` - K8s configurations
- `terraform-module-library` - IaC templates
- `istio-traffic-management` - Service mesh

### AI/ML Skills
- `rag-implementation` - Retrieval-augmented generation
- `prompt-engineering-patterns` - LLM optimization
- `langchain-architecture` - LLM application frameworks

[View complete skills reference](docs/agent-skills.md)

## Plugin Catalog

### Essential Plugins

```bash
# Development
/plugin install python-development      # Python with 5 skills
/plugin install javascript-typescript   # JS/TS with 4 skills
/plugin install backend-development     # APIs with 3 skills

# Infrastructure
/plugin install kubernetes-operations   # K8s with 4 skills
/plugin install cloud-infrastructure    # Cloud with 4 skills

# Quality
/plugin install security-scanning       # Security with SAST
/plugin install code-review-ai          # AI-powered review
```

[View complete plugin catalog](docs/plugins.md)

## Documentation

- [Agent Reference](docs/agents.md) - All 108 agents by category
- [Skills Reference](docs/agent-skills.md) - All 140 skills
- [Plugin Catalog](docs/plugins.md) - All 72 plugins
- [Usage Guide](docs/usage.md) - Commands and workflows
- [Architecture](docs/architecture.md) - Design principles

## Model Configuration

Agents are assigned to specific model tiers based on task complexity:

| Tier | Use Case |
|------|----------|
| **Opus** | Critical architecture, security, code review |
| **Sonnet** | Complex development, debugging, documentation |
| **Haiku** | Fast operations, SEO, deployment tasks |

## Repository Structure

```
prima-delivery/
├── .opencode/              # OpenCode configuration
│   ├── agents/             # 108 agent definitions
│   ├── skills/             # 140 skill packages
│   └── commands/           # Custom commands
├── .claude-plugin/         # Claude Code configuration
│   └── marketplace.json    # Plugin definitions
├── plugins/                # Plugin source files
│   ├── python-development/
│   ├── backend-development/
│   └── ...
├── docs/                   # Documentation
├── scripts/                # Build scripts
└── opencode.json           # OpenCode config
```

## License

Copyright (c) 2026 eSimplicity Inc. All Rights Reserved.

This software is proprietary and confidential. See [LICENSE](LICENSE) for details.
