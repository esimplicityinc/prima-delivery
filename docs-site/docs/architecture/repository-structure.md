---
sidebar_position: 3
title: Repository Structure
description: File organization and directory layout
---

# Repository Structure

Overview of Prima Delivery's file organization.

## Top-Level Structure

```
prima-delivery/
├── .opencode/                  # OpenCode configuration
│   ├── agents/                 # 108 agent definitions
│   ├── skills/                 # 140 skill packages
│   ├── commands/               # Custom commands
│   └── plugins/                # TypeScript plugins
│
├── .claude-plugin/             # Claude Code configuration
│   └── marketplace.json        # Plugin catalog
│
├── plugins/                    # Claude Code plugin source
│   ├── python-development/
│   ├── backend-development/
│   └── ...
│
├── docs/                       # Legacy documentation
├── docs-site/                  # Docusaurus site (this site)
├── scripts/                    # Build scripts
│
├── opencode.json               # OpenCode config
├── package.json                # npm configuration
├── LICENSE                     # Proprietary license
└── README.md                   # Project readme
```

## Agent Directory

```
.opencode/agents/
├── python-pro.md
├── typescript-pro.md
├── backend-architect.md
├── security-auditor.md
└── ... (108 files)
```

### Agent File Format

```markdown
---
description: Brief description for autocomplete
mode: subagent
model: medium
---

Agent prompt content...
```

## Skills Directory

```
.opencode/skills/
├── async-python-patterns/
│   ├── SKILL.md              # Main skill definition
│   └── references/           # Supporting materials
│       └── examples.md
│
├── kubernetes-manifest-patterns/
│   ├── SKILL.md
│   ├── assets/               # Templates
│   │   └── deployment.yaml
│   └── references/
│       └── best-practices.md
│
└── ... (140 directories)
```

### Skill Directory Format

```
skill-name/
├── SKILL.md                  # Required: Main definition
├── references/               # Optional: Reference docs
│   └── *.md
├── assets/                   # Optional: Templates, configs
│   └── *.*
└── scripts/                  # Optional: Helper scripts
    └── *.sh
```

## Plugins Directory

```
plugins/
├── python-development/
│   ├── .claude-plugin/
│   │   └── plugin.json       # Plugin metadata
│   ├── agents/
│   │   ├── python-pro.md
│   │   ├── django-pro.md
│   │   └── fastapi-pro.md
│   ├── commands/
│   │   └── python-scaffold.md
│   └── skills/
│       ├── async-python-patterns/
│       └── python-testing-patterns/
│
├── backend-development/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── agents/
│   └── skills/
│
└── ... (72 plugin directories)
```

## Documentation Site

```
docs-site/
├── docs/                     # Documentation content
│   ├── intro.md
│   ├── getting-started/
│   ├── agents/               # Generated agent pages
│   ├── skills/               # Generated skill pages
│   ├── plugins/
│   ├── usage/
│   ├── architecture/
│   └── api/
│
├── src/
│   ├── components/           # React components
│   ├── css/
│   │   └── custom.css        # Theme customization
│   └── pages/
│       └── index.tsx         # Landing page
│
├── static/
│   └── img/                  # Images and logos
│
├── scripts/
│   ├── generate-agent-docs.ts
│   └── generate-skill-docs.ts
│
├── docusaurus.config.ts      # Site configuration
├── sidebars.ts               # Navigation config
└── package.json
```

## Build Scripts

```
scripts/
├── build.ts                  # Main build orchestrator
├── convert-agents.ts         # Agent format conversion
└── convert-skills.ts         # Skill validation
```

## Configuration Files

| File | Purpose |
|------|---------|
| `opencode.json` | OpenCode configuration |
| `package.json` | npm package metadata |
| `.claude-plugin/marketplace.json` | Claude Code catalog |
| `docs-site/docusaurus.config.ts` | Documentation site config |

## File Counts

| Directory | Files/Dirs |
|-----------|------------|
| `.opencode/agents/` | 108 files |
| `.opencode/skills/` | 140 directories |
| `plugins/` | 72 directories |
| `docs-site/docs/` | ~280 pages |

## Next Steps

- [Agent Format](/docs/api/agent-format) - Agent file specification
- [Skill Format](/docs/api/skill-format) - Skill file specification
