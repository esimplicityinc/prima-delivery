# The Kata Advantage: Taxonomy-Guided vs Naive AI Agent Implementation

**Project:** prima-delivery (PRIMA-151)
**Date:** 2026-03-16
**Author:** Aaron West

---

## Experiment Design

Two AI agent sessions were given identical business requirements:

> Deploy a Docusaurus static site to AWS with dev (`dev.alvisprima.com`) and prod (`alvisprima.com`) environments using Terragrunt/Terraform, with GitHub Actions CI/CD and GitHub OIDC authentication.

**Approach A (Kata-Guided):** The orchestrator agent used the Katalyst Taxonomy CLI (`kata`) v0.14.0 to initialize project structure, create taxonomy nodes, install plugins, and then manually filled in the Terraform/Terragrunt/workflow files using the bundled templates as reference. This happened across a multi-session conversation with ~10 phases of work.

**Approach B (Naive):** A single sub-agent was given the same business requirements with NO knowledge of Kata, taxonomy conventions, or organizational frameworks. It was told: "implement it however you think is best as a cloud architect."

Both approaches produced working infrastructure code. The differences reveal what a taxonomy framework actually provides.

---

## Head-to-Head Comparison

### Agent Effort

| Metric | Kata-Guided (A) | Naive (B) |
|--------|-----------------|-----------|
| Total files created/modified | 141 | 17 |
| Custom files (hand-written) | ~20 | 17 |
| Scaffolded files (from Kata plugins) | ~121 | 0 |
| Terraform `.tf` files | 3 (1 module) | 8 (2 modules) |
| Terragrunt `.hcl` files | 3 (context + 2 env) | 5 (root + 4 env) |
| GitHub Actions workflows | 2 | 2 |
| Taxonomy metadata files | 6 (system, subsystem, stack, layer, library, version) | 0 |
| Agent tool calls | ~50+ across multiple sessions | ~18 in single session |
| Agent sessions | Multiple (10 phases over hours) | 1 (single shot) |
| Human interventions/corrections | 15+ (documented in katafix.md) | 0 |

### Speed and Token Efficiency

| Metric | Kata-Guided (A) | Naive (B) |
|--------|-----------------|-----------|
| Time to working implementation | Hours (multi-session) | ~5 minutes (single agent call) |
| Estimated token consumption | Very high (~200K+ tokens across sessions) | Low (~30K tokens, single round) |
| Correction loops | 15+ (workarounds for CLI issues) | 0 |
| Reference project consultation | Yes (prima-common2 alignment) | No (self-contained) |
| Context window pressure | High (accumulating taxonomy knowledge) | Low (fresh context, single task) |

### Quality of Output

| Dimension | Kata-Guided (A) | Naive (B) |
|-----------|-----------------|-----------|
| **Directory structure** | `docs-site/iac/composite/terraform/` (Kata convention) | `infra/terraform/modules/` + `infra/terragrunt/` (industry standard) |
| **Module separation** | 1 monolithic module (S3+CF+ACM+R53+OIDC) | 2 focused modules (static-site, github-oidc) |
| **Terraform version** | `~> 1.13` with AWS `~> 6.0` (matches Kata template) | `>= 1.5` with AWS `>= 5.0, < 6.0` (conservative) |
| **S3 bucket policy** | Inline `jsonencode()` | `aws_iam_policy_document` data source (best practice) |
| **CloudFront caching** | `forwarded_values` block (legacy) | `cache_policy_id` managed policy (modern) |
| **CloudFront URI rewrite** | Custom error response only | CloudFront Function for clean URLs + error response |
| **OIDC provider handling** | Data source + conditional create in same module | Separate module with `dependency` block and mock outputs |
| **State key** | `${system}/${subsystem}/${stack}/${env}/terraform.tfstate` | `prima-delivery/${env}/${path}/terraform.tfstate` |
| **Workflow config values** | Hardcoded `PLACEHOLDER` in env block | GitHub repository variables (`${{ vars.* }}`) |
| **Docusaurus config** | `customFields` with `deployEnv`, `isDev`, `commitUrl` | Simpler: just `COMMIT_SHA` presence toggles banner |
| **Docusaurus fallback** | Falls back to `https://alvisprima.com` (prod) | Falls back to GitHub Pages URL (backwards-compatible) |
| **Tags** | Taxonomy-derived (system_name, sub_system_name, stack_name, environment, version, iac) | Simple (ManagedBy, Project, Environment, Repository) |
| **Trailing newline in .gitignore** | Missing (had to fix manually) | Missing |

---

## What the Naive Agent Did Better

### 1. Module Separation
The naive agent split OIDC into its own module with a Terragrunt `dependency` block, which is objectively better architecture — different lifecycles, independent apply, and the `mock_outputs` pattern enables `plan` without a full dependency chain.

### 2. Modern CloudFront Configuration
Used `cache_policy_id` (AWS managed CachingOptimized policy) instead of the deprecated `forwarded_values` block. Also added a CloudFront Function for URI rewriting — a real production need for Docusaurus clean URLs that the Kata-guided approach missed.

### 3. GitHub Repository Variables
Instead of hardcoding `PLACEHOLDER` values in workflow YAML that require manual replacement post-apply, the naive agent used `${{ vars.DEV_DEPLOY_ROLE_ARN }}` — GitHub's built-in mechanism for non-secret configuration. This is a better operational pattern.

### 4. Conservative Version Pinning
`>= 5.0, < 6.0` for AWS provider is more appropriate for a new project than `~> 6.0`, which locks to a major version that many teams haven't adopted yet.

### 5. Backwards-Compatible Docusaurus Config
The fallback URL points to the existing GitHub Pages URL (`https://esimplicityinc.github.io/prima-delivery/`), so the existing `deploy-docs.yml` workflow continues to work unchanged during migration. The Kata-guided version defaulted to `https://alvisprima.com` which would break local dev without env vars.

### 6. Speed
One agent call, ~18 tool invocations, ~5 minutes, zero corrections needed. The Kata-guided approach took hours across multiple sessions with 15+ documented workarounds.

---

## What the Kata-Guided Approach Provides

### 1. Organizational Metadata
Taxonomy nodes (`system.yaml`, `sub_system.yaml`, `stack.yaml`, `layer.yaml`, `library.yaml`) provide machine-readable organizational context. These enable:
- Automated dependency mapping (`kata tax deps`)
- Tree visualization (`kata tax tree`)
- Linting against organizational rules (`kata tax lint`)
- Cross-project consistency when the same taxonomy is used across multiple repos

The naive approach has none of this — the infrastructure is self-contained but invisible to organizational tooling.

### 2. Shared Convention Library
The 100+ scaffolded plugin files (`.global/taxonomy/`) establish conventions for:
- Just task runner recipes for every layer type
- CI/CD Jinja2 templates for workflow generation
- Tool configuration (Docker, ArgoCD, Kustomize, etc.)
- Environment template patterns

Even though most aren't used for this static site project, they provide a foundation for future stacks (K8s, Docker, Lambda) without re-inventing conventions each time.

### 3. Multi-Team Consistency
The Kata taxonomy enforces a single convention for how environments are configured (`.global/iac/dev.yaml`), how Terragrunt generates context (`context.hcl`), and how metadata propagates as tags. In a multi-team organization, this prevents each team from independently inventing their own patterns.

### 4. Audit and Governance
The taxonomy metadata enables questions like:
- "What systems depend on this subsystem?"
- "Who owns this stack?"
- "What environments is this layer deployed to?"
- "What version is deployed?"

These questions are unanswerable from the naive implementation without reading code.

### 5. Rich Default Tags
The generated `provider.tf` includes `system_name`, `sub_system_name`, `stack_name`, `environment`, `version`, and `iac` tags — derived from taxonomy metadata. This enables cost allocation, drift detection, and compliance reporting at the organizational level.

---

## The Core Tradeoff

```
Kata-Guided:    High setup cost + organizational alignment = long-term governance value
Naive:          Low setup cost + local optimization        = fast, high-quality, but isolated
```

### When Kata Adds Clear Value
- **Multi-repo organizations** where 10+ repos need consistent infrastructure patterns
- **Compliance environments** requiring audit trails, ownership metadata, and dependency maps
- **Platform teams** building golden paths for product teams to follow
- **Long-lived projects** where the taxonomy metadata pays dividends over years of operations

### When the Naive Approach Wins
- **Single-repo projects** where organizational consistency is irrelevant
- **Greenfield prototypes** where speed to working infrastructure matters most
- **AI-agent-driven workflows** where the agent's general cloud architecture knowledge produces better technical decisions than following a taxonomy template
- **Small teams** where Conway's Law doesn't yet apply

---

## The AI Agent Angle

This experiment reveals a key insight about AI agents and organizational frameworks:

### The Kata Framework as Agent Guardrails

In theory, Kata provides **guardrails** that keep an AI agent on the organizational rails — enforcing conventions, naming patterns, directory structures, and metadata requirements that a naive agent wouldn't know about.

In practice, those guardrails came with significant friction:
- **15 documented workarounds** for CLI behavior that didn't match expectations
- **Multiple correction loops** to align with bundled template conventions
- **Reference project consultation** required to understand what "correct" looks like
- **High token consumption** as the agent accumulated taxonomy-specific knowledge

The naive agent, freed from these guardrails, made better individual technical decisions (module separation, modern CloudFront config, GitHub vars, version pinning) because it could apply general AWS best-practice knowledge without being constrained by a framework's opinions.

### The Paradox

The Kata framework is most valuable when humans need to coordinate across teams — but it's most costly when an AI agent has to learn and work within its constraints. The framework trades **agent efficiency** for **organizational consistency**.

A potential ideal: **use Kata to define the conventions, then generate a compact context document for the AI agent** rather than having the agent interact with the CLI directly. The agent gets the guardrails as input context (naming patterns, directory structure, tag conventions) without the CLI friction.

### Token and Cost Analysis

| Metric | Kata-Guided | Naive | Ratio |
|--------|------------|-------|-------|
| Estimated input tokens | ~150K | ~15K | 10x more |
| Estimated output tokens | ~50K | ~15K | 3.3x more |
| Total estimated tokens | ~200K | ~30K | 6.7x more |
| At Claude Opus pricing ($15/M in, $75/M out) | ~$6.00 | ~$1.35 | 4.4x more expensive |
| Agent tool calls | ~50+ | ~18 | 2.8x more |
| Human intervention points | 15+ | 0 | Infinite ratio |

*Token estimates are approximate based on file sizes, conversation lengths, and tool call patterns observed during both implementations.*

---

## Recommendations

### For This Project (prima-delivery)
The Kata taxonomy was implemented primarily to **test and document the CLI** (see `katafix.md`). The 18 findings are valuable feedback for the Kata team. For the infrastructure itself, the naive approach produced technically superior code in a fraction of the time.

### For the Kata Team
1. **Reduce CLI friction** — the 15 workarounds represent real barriers to adoption, especially for AI agent workflows
2. **Generate agent context** — produce a `.kata-context.md` or `.kata-context.json` that AI agents can consume as input, rather than requiring CLI interaction
3. **Ship working templates** — the `create layer` command should scaffold at least a skeleton Terraform module and Terragrunt configs for the specified layer type
4. **Install plugins by default** — when `--layer-type` is specified, the matching plugin should auto-install

### For AI Agent Workflows
1. **Taxonomy-as-context, not taxonomy-as-tool** — feed the agent a compact conventions doc rather than having it run CLI commands
2. **Validate after, don't constrain during** — let the agent implement freely, then run `kata tax lint` to check compliance
3. **Use the naive output as a reference** — the naive agent's module separation, modern CloudFront config, and GitHub vars pattern could be incorporated as improved Kata templates

---

## Appendix: Directory Structure Comparison

### Kata-Guided Structure
```
prima-delivery/
├── system.yaml                          # Kata: system node
├── sub_system.yaml                      # Kata: subsystem node
├── version.yaml                         # Kata: version tracking
├── Justfile                             # Kata: task runner (from plugin)
├── .taxignore                           # Kata: lint ignore
├── .global/
│   ├── iac/
│   │   ├── context.hcl                  # Terragrunt shared context
│   │   ├── dev.yaml                     # Dev environment config
│   │   └── prod.yaml                    # Prod environment config
│   └── taxonomy/                        # ~100 plugin files
│       ├── environments.yaml
│       ├── taxonomy.lock
│       ├── templates/                   # 9 node templates
│       ├── layer_types/                 # 4 layer type scaffolds
│       ├── actions/                     # Just recipes, tools
│       └── cicd/                        # Workflow Jinja2 templates
├── docs-site/
│   ├── stack.yaml                       # Kata: stack node
│   ├── iac/
│   │   ├── layer.yaml                   # Kata: layer node
│   │   ├── composite/terraform/         # Terraform module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── dev/
│   │   │   ├── environment.yaml
│   │   │   └── terragrunt.hcl
│   │   └── prod/
│   │       ├── environment.yaml
│   │       └── terragrunt.hcl
│   └── [docusaurus files...]
├── prima/prima-agents/
│   └── library.yaml                     # Kata: library node
└── .github/workflows/
    ├── deploy-docs-dev.yml
    └── deploy-docs-prod.yml
```

### Naive Structure
```
prima-delivery/
├── infra/
│   ├── terraform/modules/
│   │   ├── static-site/                 # S3 + CloudFront + ACM + Route53
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── versions.tf
│   │   └── github-oidc/                 # OIDC provider + IAM deploy role
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── versions.tf
│   └── terragrunt/
│       ├── terragrunt.hcl               # Root: state, provider, tags
│       ├── dev/
│       │   ├── static-site/terragrunt.hcl
│       │   └── github-oidc/terragrunt.hcl
│       └── prod/
│           ├── static-site/terragrunt.hcl
│           └── github-oidc/terragrunt.hcl
└── .github/workflows/
    ├── deploy-docs-dev.yml
    └── deploy-docs-prod.yml
```

**File count:** 141 (Kata) vs 17 (Naive). Of the 141 Kata files, ~121 are scaffolded plugin files not directly used by this project.
