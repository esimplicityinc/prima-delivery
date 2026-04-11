<p align="center">
  <img src="../prima-deliver-square-trans.png" alt="Prima Delivery" width="80" height="80">
</p>

# Architecture & Design Principles

Prima Delivery follows industry best practices with a focus on granularity, composability, and minimal token usage.

## Core Philosophy

### Single Responsibility Principle

- Each plugin does **one thing well** (Unix philosophy)
- Clear, focused purposes (describable in 5-10 words)
- Average plugin size: **3.4 components** (follows the recommended 2-8 pattern)
- **Zero bloated plugins** - all plugins focused and purposeful

### Composability Over Bundling

- Mix and match plugins based on needs
- Workflow orchestrators compose focused plugins
- No forced feature bundling
- Clear boundaries between plugins

### Context Efficiency

- Smaller tools = faster processing
- Better fit in LLM context windows
- More accurate, focused responses
- Install only what you need

### Maintainability

- Single-purpose = easier updates
- Clear boundaries = isolated changes
- Less duplication = simpler maintenance
- Isolated dependencies

## Granular Plugin Architecture

### Plugin Distribution

- **67 focused plugins** optimized for specific use cases
- **23 clear categories** with 1-6 plugins each for easy discovery
- Organized by domain:
  - **Development**: 4 plugins (debugging, backend, frontend, multi-platform)
  - **Security**: 4 plugins (scanning, compliance, backend-api, frontend-mobile)
  - **Operations**: 4 plugins (incident, diagnostics, distributed, observability)
  - **Languages**: 7 plugins (Python, JS/TS, systems, JVM, scripting, functional, embedded)
  - **Infrastructure**: 5 plugins (deployment, validation, K8s, cloud, CI/CD)
  - And 18 more specialized categories

### Component Breakdown

**99 Specialized Agents**

- Domain experts with deep knowledge
- Organized across architecture, languages, infrastructure, quality, data/AI, documentation, business, and SEO
- Model-optimized with three-tier strategy (High, Medium, Low) for performance and cost

**9 Agent Development & Maintenance Agents**

- Agent Maker (5 agents): guided wizard for creating new agents and skills through intake, analysis, design critique, and generation
- Agent Modifier (4 agents): evidence-based diagnosis and repair of agent behavior using session log analysis, root cause identification, and targeted fixes
- Use explicit temperature control (0.2-0.4) rather than model tiers for precise orchestration behavior

**15 Workflow Orchestrators**

- Multi-agent coordination systems
- Complex operations like full-stack development, security hardening, ML pipelines, incident response
- Pre-configured agent workflows

**71 Development Tools**

- Optimized utilities including:
  - Project scaffolding (Python, TypeScript, Rust)
  - Security scanning (SAST, dependency audit, XSS)
  - Test generation (pytest, Jest)
  - Component scaffolding (React, React Native)
  - Infrastructure setup (Terraform, Kubernetes)

**107 Agent Skills**

- Modular knowledge packages
- Progressive disclosure architecture
- Domain-specific expertise across 18 plugins
- Spec-compliant (Agent Skills Specification)

## Repository Structure

```
claude-agents/
├── .github/                       # Copilot configuration and agents
│   ├── copilot-instructions.md    # Copilot custom instructions
│   └── agents/                    # Copilot agent definitions
├── .opencode/                     # OpenCode configuration and agents
│   └── agents/                    # OpenCode agent definitions
├── .claude-plugin/
│   └── marketplace.json          # Marketplace catalog (67 plugins)
├── plugins/                       # Isolated plugin directories
│   ├── python-development/
│   │   ├── agents/               # Python language agents
│   │   │   ├── python-pro.md
│   │   │   ├── django-pro.md
│   │   │   └── fastapi-pro.md
│   │   ├── commands/             # Python tooling
│   │   │   └── python-scaffold.md
│   │   └── skills/               # Python skills (5 total)
│   │       ├── async-python-patterns/
│   │       ├── python-testing-patterns/
│   │       ├── python-packaging/
│   │       ├── python-performance-optimization/
│   │       └── uv-package-manager/
│   ├── backend-development/
│   │   ├── agents/
│   │   │   ├── backend-architect.md
│   │   │   ├── graphql-architect.md
│   │   │   └── tdd-orchestrator.md
│   │   ├── commands/
│   │   │   └── feature-development.md
│   │   └── skills/               # Backend skills (3 total)
│   │       ├── api-design-principles/
│   │       ├── architecture-patterns/
│   │       └── microservices-patterns/
│   ├── security-scanning/
│   │   ├── agents/
│   │   │   └── security-auditor.md
│   │   ├── commands/
│   │   │   ├── security-hardening.md
│   │   │   ├── security-sast.md
│   │   │   └── security-dependencies.md
│   │   └── skills/               # Security skills (1 total)
│   │       └── sast-configuration/
│   ├── c4-architecture/
│   │   ├── agents/               # C4 architecture agents
│   │   │   ├── c4-code.md
│   │   │   ├── c4-component.md
│   │   │   ├── c4-container.md
│   │   │   └── c4-context.md
│   │   └── commands/
│   │       └── c4-architecture.md
│   └── ... (62 more isolated plugins)
├── docs/                          # Documentation
│   ├── agent-skills.md           # Agent Skills guide
│   ├── agents.md                 # Agent reference
│   ├── plugins.md                # Plugin catalog
│   ├── usage.md                  # Usage guide
│   └── architecture.md           # This file
└── README.md                      # Quick start
```

## Plugin Structure

Each plugin contains:

- **agents/** - Specialized agents for that domain (optional)
- **commands/** - Tools and workflows specific to that plugin (optional)
- **skills/** - Modular knowledge packages with progressive disclosure (optional)

### Minimum Requirements

- At least one agent OR one command
- Clear, focused purpose
- Proper frontmatter in all files
- Entry in marketplace.json

### Example Plugin

```
plugins/kubernetes-operations/
├── agents/
│   └── kubernetes-architect.md   # K8s architecture and design
├── commands/
│   └── k8s-deploy.md            # Deployment automation
└── skills/
    ├── k8s-manifest-generator/   # Manifest creation skill
    ├── helm-chart-scaffolding/   # Helm chart skill
    ├── gitops-workflow/          # GitOps automation skill
    └── k8s-security-policies/    # Security policy skill
```

## Agent Skills Architecture

### Progressive Disclosure

Skills use a three-tier architecture for token efficiency:

1. **Metadata** (Frontmatter): Name and activation criteria (always loaded)
2. **Instructions**: Core guidance and patterns (loaded when activated)
3. **Resources**: Examples and templates (loaded on demand)

### Specification Compliance

All skills follow the [Agent Skills Specification]():

```yaml
---
name: skill-name # Required: hyphen-case
description: What the skill does. Use when [trigger]. # Required: < 1024 chars
---
# Skill content with progressive disclosure
```

### Benefits

- **Token Efficiency**: Load only relevant knowledge when needed
- **Specialized Expertise**: Deep domain knowledge without bloat
- **Clear Activation**: Explicit triggers prevent unwanted invocation
- **Composability**: Mix and match skills across workflows
- **Maintainability**: Isolated updates don't affect other skills

See [Agent Skills](./agent-skills.md) for complete details on the 107 skills.

## Model Configuration Strategy

### Three-Tier Architecture

The system uses a three-tier model strategy:

| Tier   | Count     | Use Case                                     |
| ------ | --------- | -------------------------------------------- |
| High   | 42 agents | Critical architecture, security, code review |
| Medium | 39 agents | Complex tasks, support with intelligence     |
| Low    | 18 agents | Fast operational tasks                       |
| Custom | 9 agents  | Agent development & maintenance (temp 0.2-0.4) |

### Selection Criteria

**Low - Fast Execution & Deterministic Tasks**

- Generating code from well-defined specifications
- Creating tests following established patterns
- Writing documentation with clear templates
- Executing infrastructure operations
- Performing database query optimization
- Handling customer support responses
- Processing SEO optimization tasks
- Managing deployment pipelines

**Medium - Complex Reasoning & Architecture**

- Designing system architecture
- Making technology selection decisions
- Performing security audits
- Reviewing code for architectural patterns
- Creating complex AI/ML pipelines
- Providing language-specific expertise
- Orchestrating multi-agent workflows
- Handling business-critical legal/HR matters

### Hybrid Orchestration

Combine models for optimal performance and cost:

```
Planning Phase (Medium) → Execution Phase (Low) → Review Phase (Medium)

Example:
backend-architect (Medium) designs API
  ↓
Generate endpoints (Low) implements spec
  ↓
test-automator (Low) creates tests
  ↓
code-reviewer (Medium) validates architecture
```

## Performance & Quality

### Optimized Token Usage

- **Isolated plugins** load only what you need
- **Granular architecture** reduces unnecessary context
- **Progressive disclosure** (skills) loads knowledge on demand
- **Clear boundaries** prevent context pollution

### Component Coverage

- **100% agent coverage** - all plugins include at least one agent
- **100% component availability** - all 99 agents accessible across plugins
- **Efficient distribution** - 3.4 components per plugin average

### Discoverability

- **Clear plugin names** convey purpose immediately
- **Logical categorization** with 23 well-defined categories
- **Searchable documentation** with cross-references
- **Easy to find** the right tool for the job

## Design Patterns

### Pattern 1: Single-Purpose Plugin

Each plugin focuses on one domain:

```
python-development/
├── agents/           # Python language experts
├── commands/         # Python project scaffolding
└── skills/           # Python-specific knowledge
```

**Benefits:**

- Clear responsibility
- Easy to maintain
- Minimal token usage
- Composable with other plugins

### Pattern 2: Workflow Orchestration

Orchestrator plugins coordinate multiple agents:

```
full-stack-orchestration/
└── commands/
    └── full-stack-feature.md    # Coordinates 7+ agents
```

**Orchestration:**

1. backend-architect (design API)
2. database-architect (design schema)
3. frontend-developer (build UI)
4. test-automator (create tests)
5. security-auditor (security review)
6. deployment-engineer (CI/CD)
7. observability-engineer (monitoring)

### Pattern 3: Agent + Skill Integration

Agents provide reasoning, skills provide knowledge:

```
User: "Build FastAPI project with async patterns"
  ↓
fastapi-pro agent (orchestrates)
  ↓
fastapi-templates skill (provides patterns)
  ↓
python-scaffold command (generates project)
```

### Pattern 4: Multi-Plugin Composition

Complex workflows use multiple plugins:

```
Feature Development Workflow:
1. backend-development:feature-development
2. security-scanning:security-hardening
3. unit-testing:test-generate
4. code-review-ai:ai-review
5. cicd-automation:workflow-automate
6. observability-monitoring:monitor-setup
```

### Pattern 5: Primary + Subagent Systems

Orchestrator agents dispatch specialized subagents through task permissions:

```
agent-maker (primary, orchestrator)
├── agent-maker-intake (subagent — gather requirements)
├── agent-maker-analyzer (subagent — scan patterns)
├── agent-maker-critic (subagent — stress-test design)
└── agent-maker-scribe (subagent — generate files)

agent-modifier (primary, orchestrator)
├── agent-modifier-analyzer (subagent — parse session logs)
├── agent-modifier-diagnoser (subagent — root cause analysis)
└── agent-modifier-fixer (subagent — apply targeted fixes)
```

**Key characteristics:**
- Primary agents use `permission.task` to allow subagent dispatch
- Subagents have `mode: subagent` and restricted tool access (e.g., `write: false` for analyzers)
- Explicit temperature control (0.2-0.4) rather than model tiers
- Read-only subagents cannot modify files; only the fixer/scribe can write

## Versioning & Updates

### Marketplace Updates

- Marketplace catalog in `.claude-plugin/marketplace.json`
- Semantic versioning for plugins
- Backward compatibility maintained
- Clear migration guides for breaking changes

### Plugin Updates

- Individual plugin updates don't affect others
- Skills can be updated independently
- Agents can be added/removed without breaking workflows
- Commands maintain stable interfaces

## Contributing Guidelines

### Adding a Plugin

1. Create plugin directory: `plugins/{plugin-name}/`
2. Add agents and/or commands
3. Optionally add skills
4. Update marketplace.json
5. Document in appropriate category

### Adding an Agent

1. Create `plugins/{plugin-name}/agents/{agent-name}.md`
2. Add frontmatter (name, description, model)
3. Write comprehensive system prompt
4. Update plugin definition

Agent files are automatically converted to platform-native formats for Copilot (`.github/agents/`), OpenCode (`.opencode/agents/`), and Claude Code during the build process.

### Adding a Skill

1. Create `plugins/{plugin-name}/skills/{skill-name}/SKILL.md`
2. Add YAML frontmatter (name, description with "Use when")
3. Write skill content with progressive disclosure
4. Add to plugin's skills array in marketplace.json

### Quality Standards

- **Clear naming** - Hyphen-case, descriptive
- **Focused scope** - Single responsibility
- **Complete documentation** - What, when, how
- **Tested functionality** - Verify before committing
- **Spec compliance** - Follow agent skills guidelines

## See Also

- [Agent Skills](./agent-skills.md) - Modular knowledge packages
- [Agent Reference](./agents.md) - Complete agent catalog
- [Plugin Reference](./plugins.md) - All 67 plugins
- [Usage Guide](./usage.md) - Commands and workflows
