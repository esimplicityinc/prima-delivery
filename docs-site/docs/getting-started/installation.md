---
sidebar_position: 1
title: Installation
description: How to install Prima Delivery for any AI coding platform
---

# Installation

Prima Delivery supports **13+ AI coding platforms** including Cursor, Claude Code, OpenCode, Windsurf, Codex, and more.

## OpenPackage Installation (Recommended)

[OpenPackage](https://openpackage.dev) provides universal installation across all supported platforms with a single command.

### Install the CLI

```bash
npm install -g opkg
```

### Install Prima Delivery

```bash
# Install full toolkit (all 71 plugins, 108 agents, 140 skills)
opkg install gh@esimplicityinc/prima-delivery

# Install to global scope (user-wide, all projects)
opkg install gh@esimplicityinc/prima-delivery -g
```

### Install Specific Plugins

```bash
# Install specific plugins
opkg install gh@esimplicityinc/prima-delivery --plugins debugging-toolkit
opkg install gh@esimplicityinc/prima-delivery --plugins python-development backend-development

# Install specific agents only
opkg install gh@esimplicityinc/prima-delivery --agents docs-architect code-reviewer

# Install specific skills only
opkg install gh@esimplicityinc/prima-delivery --skills postgresql react-state-management
```

### Supported Platforms

OpenPackage automatically detects and installs to all AI coding platforms in your environment:

| Platform | Directory | Status |
|----------|-----------|--------|
| Cursor | `.cursor/` | Supported |
| Claude Code | `.claude/` | Supported |
| OpenCode | `.opencode/` | Supported |
| Windsurf | `.windsurf/` | Supported |
| Codex | `.codex/` | Supported |
| Factory | `.factory/` | Supported |
| Kilo Code | `.kilocode/` | Supported |
| Roo | `.roo/` | Supported |
| Qwen Code | `.qwen/` | Supported |
| Kiro | `.kiro/` | Supported |
| Augment Code | `.augment/` | Supported |

### Verify Installation

```bash
# List installed packages
opkg list

# Show package details
opkg show prima-delivery
```

---

## Alternative Installation Methods

:::note
The methods below are still supported but OpenPackage is recommended for multi-platform support and easier updates.
:::

### OpenCode (Manual)

Copy the `.opencode/` directory to your project root:

```bash
# Clone or download prima-delivery
git clone https://github.com/esimplicityinc/prima-delivery.git

# Copy to your project
cp -r prima-delivery/.opencode/ /path/to/your/project/
```

Your project structure should look like:

```
your-project/
├── .opencode/
│   ├── agents/      # 108 agent definitions
│   ├── skills/      # 140 skill packages
│   ├── commands/    # Custom commands
│   └── plugins/     # TypeScript plugins
├── src/
├── package.json
└── ...
```

#### Global Installation (Manual)

Install agents and skills globally for all projects:

```bash
cp -r prima-delivery/.opencode/ ~/.config/opencode/
```

#### Verify Installation

Start OpenCode and check that agents are available:

```bash
opencode
```

Press `Tab` to see the agent autocomplete list.

### Claude Code (Manual)

#### Add the Marketplace

```bash
/plugin marketplace add prima-delivery
```

#### Install Plugins

Browse available plugins:

```bash
/plugin
```

Install specific plugins:

```bash
# Development essentials
/plugin install python-development
/plugin install javascript-typescript
/plugin install backend-development

# Infrastructure
/plugin install kubernetes-operations
/plugin install cloud-infrastructure

# Quality
/plugin install security-scanning
/plugin install code-review-ai
```

#### Verify Installation

Check installed plugins:

```bash
/plugin list
```

---

## What Gets Installed

| Component | Count | Description |
|-----------|-------|-------------|
| **Agents** | 108 | Specialized AI assistants for specific domains |
| **Skills** | 140 | Modular knowledge packages with progressive disclosure |
| **Plugins** | 71 | Workflow bundles combining agents, skills, and commands |
| **Commands** | 50+ | Slash commands for common workflows |

### Installation Locations by Platform

| Platform | Agents | Skills | Commands | Config |
|----------|--------|--------|----------|--------|
| OpenCode | `.opencode/agents/` | `.opencode/skills/` | `.opencode/commands/` | `opencode.json` |
| Claude Code | Bundled in plugins | Bundled in plugins | Plugin commands | `.claude-plugin/` |
| Cursor | `.cursor/agents/` | `.cursor/skills/` | `.cursor/commands/` | `mcp.json` |
| Windsurf | `.windsurf/agents/` | `.windsurf/skills/` | — | — |

---

## Requirements

- **Node.js**: 18.0 or later (for OpenPackage CLI)
- **OpenCode**: Version 1.1.0 or later
- **Claude Code**: Latest version
- **Other platforms**: Latest versions recommended

---

## Updating

### With OpenPackage

```bash
# Update to latest version
opkg install gh@esimplicityinc/prima-delivery

# Update specific plugins
opkg install gh@esimplicityinc/prima-delivery --plugins python-development
```

### Manual Update

```bash
# Pull latest changes
cd prima-delivery
git pull

# Re-copy to your project
cp -r .opencode/ /path/to/your/project/
```

---

## Uninstalling

### With OpenPackage

```bash
opkg uninstall prima-delivery
```

### Manual

Remove the installed directories:

```bash
rm -rf .opencode/
rm -rf .cursor/agents/ .cursor/skills/
```

---

## Troubleshooting

### Agents Not Appearing

1. Check the agents directory exists for your platform
2. Verify agent files have valid YAML frontmatter
3. Restart your AI coding tool

### Plugin Not Found (Claude Code)

1. Ensure the marketplace is added correctly
2. Use plugin names, not agent names
3. Clear cache if needed:

```bash
rm -rf ~/.claude/plugins/cache/prima-delivery
```

### OpenPackage Installation Fails

1. Ensure you have Node.js 18+ installed
2. Check network connectivity to GitHub
3. Try with verbose logging:

```bash
opkg install gh@esimplicityinc/prima-delivery --verbose
```

---

## Next Steps

- [Quick Start](/docs/getting-started/quick-start) - Start using agents immediately
- [Configuration](/docs/getting-started/configuration) - Customize your setup
- [OpenPackage Guide](/docs/getting-started/openpackage) - Advanced OpenPackage usage
