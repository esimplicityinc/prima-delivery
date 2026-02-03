---
sidebar_position: 4
title: OpenPackage Guide
description: Advanced guide to using OpenPackage with Prima Delivery
---

# OpenPackage Guide

[OpenPackage](https://openpackage.dev) is a universal package manager for AI coding agent configurations. It provides unified installation, management, and distribution of rules, commands, agents, skills, and MCPs across any platform.

## Why OpenPackage?

| Benefit | Description |
|---------|-------------|
| **Multi-platform** | Single command installs to Cursor, Claude Code, OpenCode, Windsurf, and 9+ other platforms |
| **Granular installation** | Install specific plugins, agents, or skills instead of everything |
| **Automatic conversion** | Handles platform-specific formats and conventions automatically |
| **Version management** | Semantic versioning for packages with upgrade support |
| **Private packages** | Host internal packages via private GitHub repos |

---

## Installation Commands

### Full Toolkit

```bash
# Install everything (71 plugins, 108 agents, 140 skills)
opkg install gh@esimplicityinc/prima-delivery

# Install globally (user-wide)
opkg install gh@esimplicityinc/prima-delivery -g
```

### Specific Plugins

```bash
# Single plugin
opkg install gh@esimplicityinc/prima-delivery --plugins debugging-toolkit

# Multiple plugins
opkg install gh@esimplicityinc/prima-delivery --plugins python-development backend-development tdd-workflows

# By category
opkg install gh@esimplicityinc/prima-delivery --plugins security-scanning security-compliance backend-api-security
```

### Specific Agents

```bash
# Install specific agents only
opkg install gh@esimplicityinc/prima-delivery --agents code-reviewer security-auditor

# Combine with plugins
opkg install gh@esimplicityinc/prima-delivery --plugins debugging-toolkit --agents docs-architect
```

### Specific Skills

```bash
# Install specific skills
opkg install gh@esimplicityinc/prima-delivery --skills postgresql react-state-management

# Multiple skills
opkg install gh@esimplicityinc/prima-delivery --skills async-python-patterns typescript-advanced-types kubernetes-manifest-patterns
```

---

## Platform Targeting

### Auto-Detection

OpenPackage automatically detects installed AI coding platforms by looking for their configuration directories (`.cursor/`, `.claude/`, `.opencode/`, etc.).

### Explicit Platform Selection

```bash
# Install to specific platforms only
opkg install gh@esimplicityinc/prima-delivery --platforms cursor opencode

# Install to all platforms including new ones
opkg install gh@esimplicityinc/prima-delivery --platforms cursor claude opencode windsurf codex
```

### Platform-Specific Files

Some files may have platform-specific versions. OpenPackage handles this automatically:

```
plugins/python-development/
├── agents/
│   ├── python-pro.md              # Universal version
│   ├── python-pro.cursor.md       # Cursor-specific override
│   └── python-pro.claude.md       # Claude-specific override
```

---

## Managing Packages

### List Installed Packages

```bash
# List all installed packages
opkg list

# Show details for a specific package
opkg show prima-delivery
```

### Update Packages

```bash
# Re-install to update (pulls latest from GitHub)
opkg install gh@esimplicityinc/prima-delivery

# Update specific plugins
opkg install gh@esimplicityinc/prima-delivery --plugins python-development
```

### Uninstall Packages

```bash
# Uninstall entire package
opkg uninstall prima-delivery

# Note: Individual plugins cannot be uninstalled separately yet
```

### Apply Changes

After making changes to a local package:

```bash
# Sync package changes to workspace
opkg apply prima-delivery
```

---

## Private Packages

You can host private packages in a GitHub repository for internal distribution.

### Setting Up a Private Package Repo

1. Create a private GitHub repository (e.g., `your-org/internal-agents`)

2. Add the OpenPackage structure:

```
internal-agents/
├── openpackage.yml          # Root manifest
├── agents/                  # Internal agents
│   └── company-coder.md
├── skills/                  # Internal skills
│   └── company-patterns/
│       └── SKILL.md
└── plugins/
    └── internal-tools/
        ├── openpackage.yml
        └── agents/
```

3. Create `openpackage.yml`:

```yaml
name: internal-agents
version: 1.0.0
description: Internal AI agents and skills for YourCompany
author: Your Team <team@yourcompany.com>
license: UNLICENSED

# Optional: depend on prima-delivery as a foundation
packages:
  - name: prima-delivery
    source: github:esimplicityinc/prima-delivery
    version: ^1.3.0
```

### Installing Private Packages

```bash
# From private GitHub repo (requires GitHub access)
opkg install git:https://github.com/your-org/internal-agents.git

# Specific plugins from private repo
opkg install git:https://github.com/your-org/internal-agents.git --plugins internal-tools
```

### Layered Installation

Combine public and private packages:

```bash
# 1. Install public foundation
opkg install gh@esimplicityinc/prima-delivery --plugins python-development backend-development

# 2. Layer internal tools on top
opkg install git:https://github.com/your-org/internal-agents.git
```

---

## Workspace Configuration

### openpackage.yml (Workspace)

After installation, OpenPackage creates a workspace manifest:

```yaml
# .openpackage/openpackage.yml
name: my-project
version: 0.1.0
packages:
  - name: prima-delivery
    version: ^1.3.7
  - name: internal-agents
    version: ^1.0.0
dev-packages: []
```

### Re-installing from Manifest

```bash
# Install all packages listed in workspace manifest
opkg install
```

### Index File

OpenPackage tracks installed files in `.openpackage/openpackage.index.yml`:

```yaml
# Auto-generated - do not edit manually
packages:
  prima-delivery:
    files:
      agents/python-pro.md:
        - .opencode/agents/python-pro.md
        - .cursor/agents/python-pro.md
    path: ~/.openpackage/registry/prima-delivery/1.3.7/
    version: 1.3.7
```

---

## Plugin Categories

Prima Delivery plugins are organized by category:

| Category | Plugins | Description |
|----------|---------|-------------|
| **development** | 6 | Backend, frontend, mobile, debugging |
| **languages** | 7 | Python, TypeScript, Rust, Go, JVM, etc. |
| **infrastructure** | 5 | Kubernetes, cloud, CI/CD, deployment |
| **security** | 4 | Scanning, compliance, API security |
| **testing** | 3 | Unit testing, TDD, performance testing |
| **documentation** | 3 | Docs generation, C4 architecture |
| **operations** | 4 | Incident response, observability |
| **data** | 2 | Data engineering, validation |
| **ai-ml** | 4 | LLM apps, ML ops, agent orchestration |
| **quality** | 3 | Code review, comprehensive review |
| **business** | 4 | Analytics, HR, sales automation |
| **marketing** | 4 | SEO, content marketing |

See [PLUGINS.md](https://github.com/esimplicityinc/prima-delivery/blob/main/PLUGINS.md) for the complete list.

---

## Troubleshooting

### Installation Fails

```bash
# Check Node.js version (requires 18+)
node --version

# Try with verbose output
opkg install gh@esimplicityinc/prima-delivery --verbose

# Check GitHub connectivity
curl -I https://github.com/esimplicityinc/prima-delivery
```

### Platform Not Detected

```bash
# Explicitly specify platforms
opkg install gh@esimplicityinc/prima-delivery --platforms cursor opencode

# Create platform directory first if needed
mkdir -p .cursor
opkg install gh@esimplicityinc/prima-delivery
```

### Private Repo Access Denied

```bash
# Ensure GitHub CLI is authenticated
gh auth status

# Or use HTTPS with token
opkg install git:https://YOUR_TOKEN@github.com/your-org/private-repo.git
```

### Conflicts with Existing Files

OpenPackage will warn about conflicts. Options:

```bash
# Force overwrite
opkg install gh@esimplicityinc/prima-delivery --force

# Or manually backup and remove conflicts first
mv .opencode/agents/python-pro.md .opencode/agents/python-pro.md.bak
opkg install gh@esimplicityinc/prima-delivery
```

---

## Further Reading

- [OpenPackage Documentation](https://openpackage.dev/docs)
- [OpenPackage GitHub](https://github.com/enulus/openpackage)
- [Prima Delivery Plugins](https://github.com/esimplicityinc/prima-delivery/blob/main/PLUGINS.md)
- [Installation Guide](/docs/getting-started/installation)
