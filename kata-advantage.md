# The Kata Advantage: Why Taxonomy Matters for AI-Agent Infrastructure

**Project:** prima-delivery (PRIMA-151)
**Date:** 2026-03-16
**Author:** Aaron West

---

## What This Document Is

We ran an experiment: give an AI agent identical business requirements and let it implement AWS infrastructure two ways — once guided by the Katalyst Taxonomy CLI, once completely naive ("just do what you think is best"). Both produced working code. This document analyzes what a taxonomy framework actually prevents, where the real costs hide, and at what scale the investment pays for itself.

This analysis assumes the Kata CLI works correctly — the v0.14.0 bugs documented in `katafix.md` are temporary friction, not the point. The point is what happens to an organization when AI agents build infrastructure without guardrails.

---

## The Experiment

**Same requirements, two approaches:**

| | Kata-Guided | Naive Agent |
|---|---|---|
| **Prompt** | "Use Kata to initialize taxonomy, create nodes, follow conventions" | "Deploy a Docusaurus site to S3+CloudFront with dev/prod. Do whatever you think is best." |
| **Result** | 20 hand-written files + 121 scaffolded convention files | 17 hand-written files |
| **Taxonomy metadata** | system.yaml, sub_system.yaml, stack.yaml, layer.yaml, library.yaml, version.yaml | None |
| **Works?** | Yes | Yes |

At first glance, the naive agent won: fewer files, faster execution, and it made some individually better technical choices (module separation, modern CloudFront cache policies, GitHub vars instead of placeholders). But "works for one project" and "works for an organization" are different things.

---

## What the Agent Quietly Gets Wrong Without Taxonomy

The naive agent produced good infrastructure. It also made dozens of invisible decisions that will compound into organizational debt. None of these are bugs — they're all reasonable choices that happen to be different from what every other project in the organization will do.

### 1. Directory Structure Drift

The naive agent chose:
```
infra/terraform/modules/static-site/
infra/terragrunt/dev/static-site/terragrunt.hcl
```

This is a perfectly valid Terragrunt layout. But the next agent session, given a different project, will choose something different. We know this because AI agents optimize locally — they pick whatever seems cleanest for the project in front of them. Across 5 projects you'll get:

```
Project A:  infra/terraform/modules/         (this agent's preference)
Project B:  terraform/environments/dev/      (another agent's preference)
Project C:  deploy/aws/                      (yet another)
Project D:  cloud/terragrunt/prod/           (yet another)
Project E:  iac/live/dev/                    (Gruntwork's convention)
```

Each is defensible. Together they're a nightmare. The human (or next agent) touching any project has to re-learn the layout from scratch.

**What Kata prevents:** `<stack>/iac/composite/terraform/` is the directory, period. Every project, every stack, every time. An agent working within the taxonomy can't choose a different layout because the convention is encoded in the scaffolding.

### 2. State Key Pattern Drift

The naive agent chose:
```
key = "prima-delivery/${local.env}/${path_relative_to_include()}/terraform.tfstate"
```

The Kata-guided approach uses:
```
key = "${system}/${subsystem}/${stack}/${env}/terraform.tfstate"
```

Both work. But the naive pattern encodes the repo name (`prima-delivery`) and relies on directory path, while the taxonomy pattern uses logical identifiers derived from metadata. When you need to find state files across 20 projects in the same S3 bucket, the taxonomy pattern gives you:

```
prima/delivery/docs-site/dev/terraform.tfstate
prima/delivery/api-service/prod/terraform.tfstate
prima/common/shared-infra/dev/terraform.tfstate
```

The naive pattern gives you whatever each agent decided to put there. Good luck writing a script to audit state across projects.

**What Kata prevents:** State key pattern is defined once in `.global/iac/context.hcl`. Every stack in every project inherits it. No agent can deviate.

### 3. Tagging Strategy Drift

The naive agent chose:
```hcl
tags = {
  ManagedBy   = "terragrunt"
  Project     = "prima-delivery"
  Environment = "${local.env}"
  Repository  = "esimplicityinc/prima-delivery"
}
```

The Kata-guided approach generates:
```hcl
tags = {
  system_name     = "prima"
  sub_system_name = "delivery"
  stack_name      = "docs-site"
  environment     = "dev"
  version         = "1.3.7"
  iac             = "terraform"
}
```

The naive tags are fine for one project. But across an organization:
- Cost allocation by system/subsystem/stack? Impossible with `Project = "prima-delivery"` — you'd need to parse repo names.
- "What version is deployed to prod?" — the naive tags don't track version at all.
- "Find all resources managed by Terraform across all systems" — `ManagedBy = "terragrunt"` and `iac = "terraform"` are different tag keys. Neither is wrong, but they're incompatible for cross-project queries.
- The next agent might choose `managed-by`, `managed_by`, `ManagedBy`, or `Tool`. There's no enforcement.

**What Kata prevents:** Tags are generated from taxonomy metadata in `context.hcl`. Every resource in every project gets the same tag keys with values derived from the taxonomy hierarchy. AWS Cost Explorer, Config rules, and compliance audits just work.

### 4. Provider Version Drift

The naive agent chose `>= 5.0, < 6.0`. The Kata template uses `~> 6.0`. Neither is wrong, but when Project A runs AWS provider v5.72 and Project B runs v6.3, you get:
- Different resource argument names (v6 renamed several)
- Different default behaviors (v6 changed defaults on several resources)
- Terraform modules that can't be shared between projects
- Engineers who have to remember "oh, Project A is on v5 so that argument is called X, but Project B is on v6 where it's called Y"

**What Kata prevents:** Provider version is set once in `.global/iac/context.hcl`'s `generate "versions"` block. Every stack gets the same version. Upgrades happen in one place and propagate everywhere.

### 5. Environment Configuration Drift

The naive agent inlines environment-specific values directly in each `terragrunt.hcl`:
```hcl
# dev/static-site/terragrunt.hcl
inputs = {
  bucket_name      = "prima-delivery-docs-dev"
  domain_name      = "dev.alvisprima.com"
  hosted_zone_name = "dev.alvisprima.com"
}
```

The Kata approach centralizes environment config in `.global/iac/dev.yaml`:
```yaml
region: us-east-1
domain_name: dev.alvisprima.com
hosted_zone_id: Z1234567890
```

When you add a third environment (staging), the naive approach requires editing every Terragrunt file in every stack. The Kata approach requires adding one file (`.global/iac/staging.yaml`) and one entry in `environments.yaml`.

When you need to change the region for dev (say, moving to us-west-2 for cost), the naive approach requires finding and editing every file that hardcodes `us-east-1`. The Kata approach: change one line in `dev.yaml`.

**What Kata prevents:** Environment configuration scattered across dozens of files. The centralized model means environment changes are atomic and auditable.

### 6. Naming Convention Drift

The naive agent named its S3 bucket `prima-delivery-docs-dev`. The Kata approach uses `${system}-${subsystem}-${stack}-${env}` which resolves to `prima-delivery-docs-site-dev`.

Both are fine. But the next agent session might choose:
- `esimplicity-docs-dev`
- `prima-docs-development`
- `delivery-documentation-dev`
- `pd-docs-d`

There's no enforcement mechanism. A human has to notice the inconsistency in code review.

**What Kata prevents:** Resource names are derived from taxonomy metadata. `${var.context.system_name}-${var.context.sub_system_name}-${var.context.stack_name}-${var.context.environment}` always produces a predictable, parseable name. You can find any resource in AWS by knowing its taxonomy coordinates.

### 7. OIDC Subject Claim Drift

The naive agent used:
```hcl
github_subjects = [
  "repo:esimplicityinc/prima-delivery:ref:refs/heads/main",
]
```

This is correct for dev. For prod, it used `refs/tags/v*`. But another agent session might use:
- `repo:esimplicityinc/prima-delivery:*` (too permissive)
- `repo:esimplicityinc/prima-delivery:environment:production` (different pattern)
- `repo:esimplicityinc/*:ref:refs/heads/main` (org-wide, dangerous)

There's no organizational standard for OIDC subject claims. Each agent picks what seems reasonable, and security teams can't audit consistency without reading every Terraform file in every repo.

**What Kata prevents:** OIDC patterns would be part of the Terragrunt inputs template, standardized across all projects. Deviations are visible in code review because they differ from the template.

### 8. Missing Ownership and Dependency Metadata

The naive agent created working infrastructure with zero metadata about who owns it, what depends on it, or how it relates to other systems. If the `docs-site` CloudFront distribution goes down:

- Who do you page? (no owner field anywhere)
- What depends on this? (no dependency map)
- Is this the dev or prod instance? (check tags... if they exist... if they're consistent)
- What system is this part of? (read the repo README and hope)

**What Kata provides:**
```yaml
# stack.yaml
spec:
  owners:
    - "aaron.west@esimplicity.com"
  dependsOn:
    nodes:
      - "delivery"
```

`kata tax tree` shows the full hierarchy. `kata tax deps` shows what depends on what. This isn't optional metadata — it's the organizational nervous system.

---

## The Real Cost of Organizational Misalignment

The drift described above isn't hypothetical. It's what happens in every organization that lets individual teams (or individual agent sessions) make infrastructure decisions independently. The cost manifests in four ways:

### 1. Discovery Cost (every interaction)

Every time a human or agent touches a project without taxonomy, they pay a discovery tax:

| Operation | With taxonomy | Without taxonomy |
|-----------|--------------|-----------------|
| Find the Terraform | `<stack>/iac/composite/terraform/` | `grep -r "resource.*aws" .` |
| Find environment config | `.global/iac/<env>.yaml` | Could be anywhere — inline, in vars, in GitHub, in SSM |
| Run a plan | `just plan` | Figure out the right directory, the right command, the right flags |
| Find the owner | `stack.yaml` → owners field | Git blame, Slack, tribal knowledge |
| Understand dependencies | `kata tax deps` | Read every file, build mental model |
| Verify what's deployed where | `layer.yaml` → environments | Check AWS console, check workflow files |

This tax is paid on **every interaction** — not just setup. Over a year across 10 projects with 5 engineers, it compounds into weeks of lost productivity.

### 2. Incident Response Cost (when it matters most)

At 2 AM when production is down, you need to:
1. Find the infrastructure code for the affected service
2. Understand what's deployed and how
3. Find the right credentials/access
4. Fix the problem

With consistent taxonomy, steps 1-3 are muscle memory. Without it, they're an investigation. The difference is 5 minutes vs 30 minutes — and in an outage, that's the difference between a blip and a customer-facing incident.

### 3. Onboarding Cost (every new team member or agent session)

**Without taxonomy:** "Project A works like this, Project B is different, Project C has its own thing going on." Each project is a new learning curve. A new engineer takes 2+ weeks to internalize the infrastructure patterns across 5 projects.

**With taxonomy:** "Everything follows System → Subsystem → Stack → Layer. Terraform is in `composite/terraform/`. Environments are in `.global/iac/`. Tags come from taxonomy metadata. Run `just plan`." One pattern, learned once, applied everywhere. A new engineer (or a new AI agent session) is productive in hours, not weeks.

### 4. Compliance and Audit Cost (periodic but expensive)

"Show me all production resources, their owners, and when they were last deployed."

**With taxonomy:** `kata tax tree --env prod` + AWS tag query on `environment=prod`. Done.

**Without taxonomy:** Manual audit of every repo, every Terraform state file, every workflow file, every AWS account. Days of work, repeated quarterly.

---

## Cognitive Load: The Invisible Multiplier

Cognitive load doesn't add linearly — it multiplies. Each unique convention set you have to remember compounds with every other one:

```
1 project:   1 convention to learn                  → cognitive load ≈ 1
3 projects:  3 conventions + switching overhead      → cognitive load ≈ 5
5 projects:  5 conventions + switching overhead      → cognitive load ≈ 12
10 projects: 10 conventions + switching overhead     → cognitive load ≈ 30
10 projects: 1 convention (taxonomy)                 → cognitive load ≈ 2
```

The switching overhead comes from **mental cache misses**. You can't keep 5 different directory layouts in your head simultaneously. Every time you move from Project A to Project C, you have to flush your mental model and re-learn. With taxonomy, there's nothing to flush — it's always the same.

### The team dimension

```
Cognitive load = (projects) × (people) × (unique conventions)

Without taxonomy:  5 projects × 4 engineers × 5 conventions = 100 learning events
With taxonomy:     5 projects × 4 engineers × 1 convention  =  20 learning events
```

That's an 80% reduction in organizational learning cost. And it compounds every time you add a project, a team member, or an AI agent session.

### The AI agent version

AI agents have their own cognitive load problem: **context window consumption and session amnesia**.

Without taxonomy, every new agent session burns 5-10 tool calls just to understand the project layout. It reads README files, greps for patterns, infers conventions. If the session ends, all that learned context evaporates. The next session starts from zero.

With taxonomy, the agent reads 4 files — `system.yaml`, `sub_system.yaml`, `stack.yaml`, `.global/iac/context.hcl` — and knows everything. The taxonomy IS the compressed context that survives session boundaries. It's the organizational memory that agents lack.

---

## Where the Taxonomy Keeps Agents on the Rails

This is the core value proposition. AI agents are excellent at implementing infrastructure from requirements. They are terrible at maintaining organizational consistency across sessions, projects, and teams. Here's where taxonomy acts as guardrails:

### Prevents: Inventing new conventions

Without taxonomy, every agent session starts from first principles. "Where should I put the Terraform? I think `infra/` is clean." The next session: "I'll use `terraform/`." The next: "Let me put it in `deploy/`." Each is a reasonable local decision that creates global chaos.

**Taxonomy guardrail:** The directory structure is pre-defined. The agent fills in files within the structure; it doesn't design the structure.

### Prevents: Inconsistent resource naming

An agent names an S3 bucket `my-site-dev`. Another names it `company-docs-development`. Another names it `prod-static-hosting`. None are wrong. All are incompatible with cross-project tooling.

**Taxonomy guardrail:** Names are derived from `${system}-${subsystem}-${stack}-${env}`. The agent provides the Terraform logic; the naming is inherited from metadata.

### Prevents: Tag strategy fragmentation

Tags are where organizational misalignment costs real money (broken cost allocation, failed compliance queries, useless dashboards). Every agent invents its own tags because there's no shared standard to follow.

**Taxonomy guardrail:** `context.hcl` generates provider-level default tags from taxonomy metadata. The agent never touches tags — they're injected automatically.

### Prevents: State backend inconsistency

State key patterns determine whether you can find and manage Terraform state across projects. An agent picks whatever path structure seems logical. Across 20 projects, you get 20 different key patterns in the same S3 bucket.

**Taxonomy guardrail:** State key is `${system}/${subsystem}/${stack}/${env}/terraform.tfstate`, defined once in `context.hcl`. Every stack in every project follows the same pattern.

### Prevents: Missing operational metadata

An agent builds infrastructure that works but is operationally opaque. No owner. No dependency map. No environment list. No version tracking. When something breaks, you're in discovery mode.

**Taxonomy guardrail:** `stack.yaml` requires owners. `layer.yaml` requires environment lists. `dependsOn` maps dependencies. These aren't optional fields — they're part of the taxonomy node schema.

### Prevents: Environment configuration sprawl

An agent inlines environment-specific values wherever they're needed. Region here, domain there, account ID somewhere else. When you need to change something for an environment, you're grepping across dozens of files.

**Taxonomy guardrail:** Environment config lives in `.global/iac/<env>.yaml`. One file per environment. Changes propagate through `context.hcl` to all stacks automatically.

### Prevents: Provider version skew

Agent A pins AWS provider `~> 5.0`. Agent B pins `~> 6.0`. Your Terraform modules are now incompatible across projects. Shared modules break. Engineers have to remember which version each project uses.

**Taxonomy guardrail:** Provider version is generated by `context.hcl`. All projects use the same version. Upgrades are a one-line change that affects everything.

---

## The Break-Even Analysis

The taxonomy has a real setup cost. For a mature CLI, that cost is approximately:

| Activity | Time |
|----------|------|
| `kata tax init` + plugin installation | 5 minutes |
| Create taxonomy nodes (system, subsystem, stack, layer) | 5 minutes |
| Configure `.global/iac/context.hcl` and environment YAMLs | 15 minutes |
| Write Terraform modules (same effort as naive) | Same |
| Write Terragrunt configs (simpler — inherits from context.hcl) | Less |
| Write GitHub Actions workflows (same effort) | Same |

**First stack overhead vs naive: ~25 minutes** (the taxonomy metadata and global config that a naive approach skips).

**Second stack overhead vs naive: ~5 minutes** (3 kata commands + modify Terraform; everything else is inherited).

**Third+ stack overhead: near zero** — the taxonomy is already there, `context.hcl` handles state/provider/tags, environment configs exist. You're just writing the new Terraform module.

### The curve

```
             Cumulative organizational cost
              (discovery + drift + incidents + compliance + onboarding)
              
  Naive ─────────────/
  approach          /
                   /
                  /                          The gap only widens
                 /
                /───────────────────────────────────── Taxonomy
               /                                       approach
              /
  ───────────┼───────────────────────────────────────────→
             1     2     3     5     10    15    20    Projects
             
  ↑ Taxonomy setup cost (one-time, ~25 min for a working CLI)
```

| Projects | Naive: cumulative drift cost | Taxonomy: cumulative overhead |
|----------|---------------------------|------------------------------|
| 1 | Low (manageable) | Slightly higher (setup cost) |
| 2 | Medium (first inconsistencies appear) | Lower (second stack nearly free) |
| 3 | High (3 different conventions to manage) | Much lower (all inherited) |
| 5 | Very high (discovery tax on every interaction) | Minimal (muscle memory) |
| 10 | Unsustainable (dedicated documentation needed) | Near-zero marginal cost |
| 20 | Crisis (nobody knows how anything works) | Same marginal cost as project 3 |

**Break-even: ~2 projects.** After that, every project without taxonomy is adding organizational debt. Every project with taxonomy is paying into a shared infrastructure that makes all projects easier to operate.

---

## What the Naive Agent Actually Demonstrated

The naive agent proved that AI agents are excellent cloud architects in isolation. Given good requirements, an agent will produce clean, well-structured, production-quality infrastructure code in minutes.

What the naive agent also demonstrated — invisibly — is that:

1. **Its decisions are non-transferable.** The next agent session will make different decisions. You can't ask it to "follow the same pattern as Project A" without feeding it Project A's entire codebase as context.

2. **Its conventions are ephemeral.** Once the session ends, the reasoning behind every decision is gone. Why `infra/` instead of `iac/`? Why `>= 5.0, < 6.0`? Why `ManagedBy` instead of `managed_by`? Nobody remembers, and the code doesn't explain.

3. **Its output is organizationally opaque.** There's no machine-readable way to answer "what does this project contain?", "who owns this?", or "what depends on what?" without reading every file.

4. **Its quality is prompt-dependent.** The naive agent got a detailed prompt that pre-decided architecture, auth patterns, domains, state buckets, and environments. Without that prompt, it would have needed multiple clarification rounds and may have made wrong assumptions. The taxonomy replaces that prompt — it IS the pre-decided architecture, encoded in files.

### The prompt IS the taxonomy

Here's the key insight: **the detailed prompt we gave the naive agent was functionally equivalent to a taxonomy.** It codified architectural decisions, naming patterns, environment structure, and deployment strategy. The only difference is:

| | The prompt | The taxonomy |
|---|---|---|
| **Format** | English prose in a chat session | YAML files in a repo |
| **Durability** | Gone when session ends | Persists in version control |
| **Machine-readable** | No | Yes (`kata tax tree`, `kata tax deps`, `kata tax lint`) |
| **Reusable across sessions** | Must be re-written or copy-pasted | Inherited automatically |
| **Reusable across projects** | No (specific to one project) | Yes (shared conventions) |
| **Enforceable** | No (agent can ignore it) | Yes (`kata tax lint` catches violations) |
| **Discoverable by new team members** | Only if someone shares it | Always in the repo |

The taxonomy is a **durable, machine-readable, enforceable, discoverable prompt** that every agent session and every team member inherits automatically. The naive approach requires a human to write that prompt fresh every time — and hope they remember all the decisions.

---

## Recommendations

### For organizations evaluating taxonomy tools
- Don't evaluate on "does it make the first project faster" — it won't
- Evaluate on "what happens at project 5, 10, 20 without shared conventions"
- The taxonomy tax is paid once; the drift tax is paid forever
- If you have 1 project and 1 engineer, skip it — the overhead isn't justified
- If you have 3+ projects, 2+ engineers, or AI agents building infrastructure: you need conventions, whether from Kata or something else

### For AI agent workflows
- **Taxonomy-as-context:** Feed the agent taxonomy files as input context, not as CLI commands to run. The agent reads `system.yaml`, `context.hcl`, `environments.yaml` and knows the conventions. It implements within them.
- **Validate after, don't constrain during:** Let the agent write code freely, then run `kata tax lint` to verify compliance. This gets the best of both worlds — agent creativity within organizational guardrails.
- **The agent doesn't need to run `kata tax init`:** The taxonomy should already exist. The agent's job is to create new stacks/layers within the existing taxonomy, not to set up the taxonomy itself.

### For the Kata team
- The CLI's primary user will increasingly be AI agents, not humans
- Optimize for **"agent reads taxonomy files and implements within conventions"** not **"agent runs kata commands"**
- The most valuable output is the `.global/` directory and the taxonomy metadata files — these are what constrain agents
- Consider generating a `.kata-context.json` that summarizes all conventions in one file an agent can consume in a single read

---

## Appendix A: What the Naive Agent Chose vs Taxonomy Convention

| Decision Point | Naive Agent Choice | Taxonomy Convention | Drift Risk |
|---|---|---|---|
| Top-level directory | `infra/` | `<stack>/iac/` | High — every agent picks differently |
| Terraform module path | `infra/terraform/modules/static-site/` | `<stack>/iac/composite/terraform/` | High |
| Terragrunt root | `infra/terragrunt/terragrunt.hcl` | `.global/iac/context.hcl` | Medium |
| Environment config location | Inline in terragrunt.hcl | `.global/iac/<env>.yaml` | High |
| State key pattern | `prima-delivery/${env}/${path}/...` | `${system}/${subsystem}/${stack}/${env}/...` | High |
| S3 bucket name | `prima-delivery-docs-dev` | `${system}-${subsystem}-${stack}-${env}` | High |
| AWS provider version | `>= 5.0, < 6.0` | `~> 6.0` (from template) | Medium |
| Terraform version | `>= 1.5` | `~> 1.13` (from template) | Low |
| Default tags | `ManagedBy, Project, Environment, Repository` | `system_name, sub_system_name, stack_name, environment, version, iac` | Very high |
| Workflow config values | `${{ vars.* }}` (GitHub vars) | Environment variables in workflow YAML | Low |
| Owner metadata | None | `stack.yaml` → owners field | Critical |
| Dependency metadata | None | `dependsOn` in taxonomy nodes | Critical |
| Environment list | Implicit (directory exists = environment exists) | Explicit in `layer.yaml` and `environments.yaml` | Medium |

## Appendix B: Directory Structure Comparison

### Kata-Guided Structure
```
prima-delivery/
├── system.yaml                          # "What system is this?"
├── sub_system.yaml                      # "What subsystem?"  
├── version.yaml                         # "What version?"
├── Justfile                             # "How do I operate this?"
├── .global/
│   ├── iac/
│   │   ├── context.hcl                  # "How is state/provider/tags configured?"
│   │   ├── dev.yaml                     # "What are dev's parameters?"
│   │   └── prod.yaml                    # "What are prod's parameters?"
│   └── taxonomy/                        # Convention library (~100 files)
│       ├── environments.yaml            # "What environments exist?"
│       ├── layer_types/                 # "What infrastructure patterns are available?"
│       ├── actions/                     # "How do I plan/apply/destroy?"
│       └── cicd/                        # "How do pipelines work?"
├── docs-site/
│   ├── stack.yaml                       # "Who owns this? What envs? What depends on it?"
│   └── iac/
│       ├── layer.yaml                   # "What layer type? What environments?"
│       ├── composite/terraform/         # The actual infrastructure code
│       ├── dev/terragrunt.hcl           # Dev environment binding
│       └── prod/terragrunt.hcl          # Prod environment binding
└── .github/workflows/
    ├── deploy-docs-dev.yml
    └── deploy-docs-prod.yml
```

### Naive Structure
```
prima-delivery/
├── infra/
│   ├── terraform/modules/
│   │   ├── static-site/                 # Infrastructure code (good)
│   │   └── github-oidc/                 # Separated module (good)
│   └── terragrunt/
│       ├── terragrunt.hcl               # Root config (good)
│       ├── dev/                          # Dev bindings (good)
│       └── prod/                         # Prod bindings (good)
└── .github/workflows/
    ├── deploy-docs-dev.yml
    └── deploy-docs-prod.yml

# Missing: owner metadata, dependency map, environment list, version tracking,
# operational recipes, convention library, organizational context
```

The naive structure answers "how does this infrastructure work?" The taxonomy structure answers that AND "how does this infrastructure relate to everything else in the organization?"
