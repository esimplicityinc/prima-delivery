---
sidebar_position: 1
title: Installation
description: How to install Prima Delivery for OpenCode and Claude Code
---

# Installation

Prima Delivery supports two AI coding platforms: **OpenCode** and **Claude Code**.

## OpenCode Installation

### Project-Level (Recommended)

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

### Global Installation

Install agents and skills globally for all projects:

```bash
cp -r prima-delivery/.opencode/ ~/.config/opencode/
```

### Verify Installation

Start OpenCode and check that agents are available:

```bash
opencode
```

Press `Tab` to see the agent autocomplete list.

## Claude Code Installation

### Add the Marketplace

```bash
/plugin marketplace add prima-delivery
```

### Install Plugins

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

### Verify Installation

Check installed plugins:

```bash
/plugin list
```

## What Gets Installed

| Component | OpenCode | Claude Code |
|-----------|----------|-------------|
| **Agents** | `.opencode/agents/` (108 files) | Bundled in plugins |
| **Skills** | `.opencode/skills/` (140 dirs) | Bundled in plugins |
| **Commands** | `.opencode/commands/` | Plugin commands |
| **Config** | `opencode.json` | `.claude-plugin/` |

## Requirements

- **OpenCode**: Version 1.1.0 or later
- **Claude Code**: Latest version
- **Node.js**: 18.0 or later (for build scripts)

## Troubleshooting

### Agents Not Appearing

1. Check the `.opencode/agents/` directory exists
2. Verify agent files have valid YAML frontmatter
3. Restart OpenCode

### Plugin Not Found (Claude Code)

1. Ensure the marketplace is added correctly
2. Use plugin names, not agent names
3. Clear cache if needed:

```bash
rm -rf ~/.claude/plugins/cache/prima-delivery
```

## Next Steps

- [Quick Start](/docs/getting-started/quick-start) - Start using agents immediately
- [Configuration](/docs/getting-started/configuration) - Customize your setup
