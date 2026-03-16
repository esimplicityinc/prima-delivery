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

## The Hidden Cost: What the Naive Agent Got for Free

The comparison above has a critical blind spot: **the naive agent's prompt was itself a compressed knowledge artifact.** That prompt didn't come from nowhere — it was written by a human who had just spent hours doing the Kata-guided implementation and knew exactly what to ask for.

### What the prompt pre-decided for the agent

The naive agent received these decisions gift-wrapped in its instructions:

| Decision | Who actually made it | Cost to figure out |
|----------|---------------------|-------------------|
| "Use S3 + CloudFront + OAC" | Human (from experience) | Research AWS static hosting options, evaluate OAC vs OAI vs public bucket |
| "Use ACM with DNS validation via Route53" | Human | Research certificate options, understand CloudFront requires us-east-1 |
| "Use GitHub OIDC for keyless CI/CD" | Human | Research IAM auth patterns, understand OIDC trust policies |
| "Use Terragrunt wrapping Terraform" | Human | Evaluate Terragrunt vs Terraform workspaces vs CDK vs Pulumi |
| "Two environments: dev and prod" | Human (business requirement) | Stakeholder conversations |
| "Dev = push to main, Prod = release publish" | Human (release strategy) | Design deployment strategy, evaluate options |
| "Commit SHA banner on dev" | Human (UX requirement) | Determine what dev differentiation is needed |
| "State bucket name and DynamoDB table" | Human (existing infra knowledge) | Know your AWS account, find existing resources |
| "Hosted zones already exist" | Human (existing infra knowledge) | Audit existing Route53 configuration |
| "Use npm for docs-site" | Human (project knowledge) | Know the existing build system |
| "`DOCUSAURUS_URL` env var pattern" | Human (Docusaurus knowledge) | Read Docusaurus docs on environment-aware config |

**Without this prompt, a naive agent would need to:**

1. **Discover the project** — read package.json, docusaurus.config.ts, existing workflows, understand it's a Docusaurus site
2. **Research hosting options** — evaluate GitHub Pages vs S3+CloudFront vs Vercel vs Netlify vs Amplify
3. **Ask clarifying questions** — "What domain?", "What AWS account?", "State bucket?", "Environments?", "Deploy trigger?"
4. **Make IaC tool decisions** — Terraform vs CDK vs CloudFormation? Terragrunt vs workspaces?
5. **Design the architecture** — what resources? What auth pattern? How to handle certificates?
6. **Iterate on mistakes** — wrong assumptions about existing infrastructure, missing resources, auth failures

This discovery and decision-making phase is exactly what Kata aims to eliminate by codifying decisions into the taxonomy structure.

### What Kata codifies that the prompt had to spell out

The Kata taxonomy, when populated, answers all of these questions via machine-readable metadata:

| Question | Kata answer | Naive agent needs... |
|----------|-------------|---------------------|
| What system is this? | `system.yaml` → `prima` | Human to say "this is the prima system" |
| What's the subsystem? | `sub_system.yaml` → `delivery` | Human to explain repo purpose |
| What environments exist? | `environments.yaml` → `dev, prod` | Human to specify environments |
| What IaC tool? | `layer.yaml` → `layerType: iac-terragrunt` | Human to choose Terragrunt |
| Where's the state bucket? | `.global/iac/context.hcl` → hardcoded | Human to provide bucket name |
| What region? | `.global/iac/dev.yaml` → `us-east-1` | Human to specify |
| What domain? | `.global/iac/dev.yaml` → `dev.alvisprima.com` | Human to specify |
| Who owns this? | `stack.yaml` → `aaron.west@esimplicity.com` | Human to specify or leave ambiguous |
| What tags to apply? | `context.hcl` → generates system/subsystem/stack/env/version tags | Human to define tagging strategy |
| What directory convention? | Plugin templates → `composite/terraform/` | Agent invents its own (or human specifies) |

### The real cost comparison

A fairer comparison would measure the **total human + agent effort** from "I want to deploy this site" to "working infrastructure code":

| Phase | Kata-Guided | Naive (honest accounting) |
|-------|-------------|--------------------------|
| **Human: Define requirements** | Minimal — Kata structure prompts the questions | High — must write a detailed prompt covering architecture, auth, domains, state, environments, build system |
| **Human: Architectural decisions** | Partially codified in Kata layer types and templates | Must be made upfront and encoded in prompt |
| **Human: Discover existing infra** | Still manual (state bucket, hosted zones) | Still manual (same) |
| **Agent: Scaffold structure** | `kata tax init` + plugins (~5 min, but 15 workarounds) | Agent invents structure (~2 min, but no organizational alignment) |
| **Agent: Write infrastructure code** | Manual, guided by plugin templates | Manual, guided by general knowledge |
| **Agent: Write CI/CD** | Manual (templates are placeholders) | Manual (same) |
| **Human: Review and correct** | 15 workarounds documented | Review agent output for correctness |
| **Total human time** | ~1 hour of Kata wrestling + ~30 min review | ~30 min writing prompt + ~15 min review |
| **Reusability for next stack** | High — taxonomy, context.hcl, environments all reusable | Low — must write another detailed prompt |

### The compounding advantage

The key insight is **amortization**. For a single stack (docs-site), the naive approach wins hands down. But consider what happens when you add a second stack (e.g., an API service):

**Kata-guided, second stack:**
- `kata tax create stack api-service --parent delivery`
- `kata tax create layer iac --parent api-service --layer-type iac-terragrunt`
- Copy and modify Terraform from docs-site
- Environments, state backend, provider config, tags — all inherited from `.global/iac/context.hcl`
- Agent prompt: "Add an API service stack following the existing docs-site pattern"

**Naive, second stack:**
- Write another detailed prompt specifying all architectural decisions again
- Agent may or may not follow the same conventions as the first stack
- Different directory structure? Different tagging? Different state key pattern?
- No organizational metadata linking the two stacks
- If a different human (or agent session) does it, drift is almost guaranteed

**Kata-guided, tenth stack:**
- Same 3 commands + modify Terraform
- Everything else inherited
- Organizational consistency guaranteed

**Naive, tenth stack:**
- Same effort as the first time, every time
- Convention drift compounds
- No machine-readable way to audit consistency across stacks

### What this means for Kata's value proposition

Kata's value is NOT "it makes the first stack faster" — it demonstrably doesn't. Kata's value is:

1. **Decision codification** — architectural decisions made once, applied everywhere
2. **Convention durability** — the taxonomy survives team turnover, agent session boundaries, and memory loss
3. **Amortized cost** — the 121 scaffolded files and 15 workarounds are a one-time cost; every subsequent stack benefits
4. **Guardrails for the uninformed** — a new team member (or a new agent session) can't accidentally deviate from conventions because the taxonomy structure constrains them
5. **Organizational observability** — `kata tax tree` and `kata tax deps` answer questions that are unanswerable from a naive file tree

The naive approach is a **local optimum** — best for this one stack, this one time, with this one knowledgeable human writing the prompt. Kata is a **global optimum** — worse for any single stack, but better across an organization's entire infrastructure portfolio.

### The prompt engineering tax

There's a hidden "prompt engineering tax" in the naive approach that scales linearly:

```
Naive cost per stack  = (human prompt writing) + (agent execution) + (human review)
Kata cost per stack   = (kata commands) + (agent execution) + (human review)
Kata one-time cost    = (initial setup) + (workaround documentation) + (plugin installation)

Break-even point ≈ 2-3 stacks (where Kata's reusable context offsets its setup cost)
```

For an organization with 10+ stacks across multiple repos, the prompt engineering tax of the naive approach becomes the dominant cost — and it's the cost that's invisible because it looks like "the human just knows what to ask for."

### The Just recipes, CI/CD templates, and "all that scaffolding"

The 121 plugin files that looked like bloat in the per-file comparison actually represent:

| Plugin | Files | What it provides |
|--------|-------|-----------------|
| **just** | ~30 | Task runner recipes for every layer type — `just plan`, `just apply`, `just destroy`, `just lint`, Docker build/push, K8s deploy, ECR/GHCR push, security scanning (trivy, semgrep, kubesec) |
| **layer-types** | ~40 | Reference implementations for iac-terragrunt, app-docker, k8s-argocd, k8s-kustomize — complete with Dockerfiles, Kustomize overlays, ArgoCD application specs |
| **cicd** | ~15 | Jinja2 workflow templates for GitHub Actions — dev/staging/prod pipeline stages, job definitions per layer type |
| **layer-actions** | ~5 | Action metadata linking layer types to tool configurations |

A naive agent implementing all of this from scratch would need to:
- Design a Just-based task runner with recipes for Terraform plan/apply/destroy
- Write Docker build/push/scan recipes
- Write Kubernetes deploy/lint/validate recipes  
- Write security scanning integration (trivy, semgrep, kubesec, polaris, kube-linter)
- Write CI/CD pipeline templates for 3 environments × 4 layer types
- Write environment utility scripts

**Estimated naive agent effort for the full plugin set:** 3-5 separate agent sessions, ~100K+ additional tokens, significant domain expertise in K8s, Docker, and security tooling. The naive agent we ran only implemented the docs-site — it didn't touch any of this because we didn't ask for it. But the Kata plugins delivered it as a side effect of initialization.

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
