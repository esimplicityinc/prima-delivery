# Contributing to Prima Delivery

Internal contribution guidelines for the Prima Team.

## Development Setup

```bash
# 1. Clone the repository
git clone https://github.com/esimplicityinc/prima-delivery.git
cd prima-delivery

# 2. Install dependencies (installs lefthook git hooks automatically)
bun install

# 3. Verify hooks are active
git commit --allow-empty -m "test: verify hooks" --dry-run
```

**Prerequisites:** [Bun](https://bun.sh/) (root project), [Node.js 18+](https://nodejs.org/) (docs-site uses npm)

## Workflow

```
fork/branch → conventional commit → PR → CI + review → merge
```

### 1. Create a Branch

```bash
git checkout -b feat/my-new-agent
```

Use a descriptive branch name prefixed with the change type: `feat/`, `fix/`, `docs/`, `chore/`, etc.

### 2. Make Changes

See the sections below for adding agents or skills.

### 3. Commit with Conventional Commits

All commits **must** follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <description>
```

**Allowed types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`, `improve`

**Examples:**

```bash
git commit -m "feat(agent): add kubernetes-debugger agent"
git commit -m "fix: correct model tier in python-pro agent"
git commit -m "docs: update quick-start guide for Copilot"
```

Commitlint enforces this via a `commit-msg` hook — malformed messages are rejected locally.

### 4. Push and Open a PR

```bash
git push -u origin feat/my-new-agent
```

Open a PR against `main`. The PR template will guide you through the checklist.

### 5. CI + Review

CI runs automatically on all PRs with three jobs:

| Job | What it checks |
|-----|----------------|
| **validate** | `bun run validate` — skill/agent frontmatter |
| **build-openpackage** | Generates and validates OpenPackage manifests |
| **build-docs** | Builds the Docusaurus documentation site |

All three must pass. At least one review from `@esimplicity/prima` is required.

### 6. Merge

Squash-merge is recommended for feature branches. The merge commit message should follow conventional commit format.

## Adding New Agents

1. Create a new markdown file in `plugins/{plugin}/agents/`
2. Include YAML frontmatter with:
   - `description`: Clear description of the agent's purpose
   - `mode`: `subagent` (default) or `primary`
   - `model`: Target model tier (`high` / `medium` / `low`) — **never** use specific model names
3. Write comprehensive system prompt
4. Run validation: `bun run validate`

Agent files are automatically converted to platform-native formats for Copilot (`.github/agents/`), OpenCode (`.opencode/agents/`), and other platforms during the build process.

## Adding New Skills

1. Create a directory in `.opencode/skills/{skill-name}/`
2. Add `SKILL.md` with:
   - `name`: Lowercase, hyphen-separated identifier
   - `description`: Include "Use when..." activation criteria
3. Add any reference files in `references/` subdirectory

## Testing Changes

```bash
# Validate all skills and agents
bun run validate

# Rebuild OpenCode configuration
bun run build

# Build OpenPackage manifests
bun run build:openpackage
```

## Release Process

Releases are tag-driven. When a new version is ready:

```bash
# 1. Update version in package.json and openpackage.yml
# 2. Generate changelog
bun run changelog

# 3. Commit, tag, and push
git add -A
git commit -m "chore: release v1.4.0"
git tag v1.4.0
git push && git push --tags
```

The `release.yml` workflow automatically:
- Generates release notes from conventional commits
- Creates a GitHub Release
- Uploads OpenPackage manifest artifacts

## Questions

Contact the Prima Team lead for guidance on contributions.
