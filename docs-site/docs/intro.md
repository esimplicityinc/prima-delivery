---
sidebar_position: 1
title: Introduction
description: Prima Delivery - Internal AI Development Toolkit with 108 Agents, 140 Skills, and 72 Plugins
---

# Prima Delivery

<div className="hero">
  <img src="/prima-delivery/img/logo.png" alt="Prima Delivery" className="hero__logo" />
</div>

**Prima Delivery** is an internal AI development toolkit featuring **108 specialized agents**, **140 skills**, and **72 plugins** for accelerated software development.

## What's Inside

<div className="stats-grid">
  <div className="stat-item">
    <div className="stat-item__number">108</div>
    <div className="stat-item__label">AI Agents</div>
  </div>
  <div className="stat-item">
    <div className="stat-item__number">140</div>
    <div className="stat-item__label">Skills</div>
  </div>
  <div className="stat-item">
    <div className="stat-item__number">72</div>
    <div className="stat-item__label">Plugins</div>
  </div>
</div>

## Key Features

### Specialized Agents

Domain experts covering:
- **Architecture** - Backend, frontend, cloud, database design
- **Languages** - Python, TypeScript, Rust, Go, Java, and more
- **Infrastructure** - Kubernetes, Terraform, CI/CD
- **Quality** - Testing, security, code review
- **AI/ML** - LLM applications, RAG, embeddings

### Modular Skills

Knowledge packages with progressive disclosure:
- Load expertise only when needed
- Automatic activation based on context
- Detailed references and examples

### Workflow Plugins

Pre-configured bundles for common tasks:
- Full-stack development
- Security hardening
- ML pipelines
- Incident response

## Supported Platforms

Prima Delivery works with both:

| Platform | Installation |
|----------|--------------|
| **OpenCode** | Copy `.opencode/` to your project |
| **Claude Code** | `/plugin marketplace add prima-delivery` |

## Quick Start

```bash
# OpenCode - Copy to your project
cp -r .opencode/ /path/to/your/project/

# Or install globally
cp -r .opencode/ ~/.config/opencode/
```

Then use agents with `@` mentions:

```
@python-pro Help me optimize this function

@backend-architect Design a REST API for user management

@security-auditor Review this code for vulnerabilities
```

## Next Steps

- [Installation Guide](/docs/getting-started/installation) - Detailed setup instructions
- [Quick Start](/docs/getting-started/quick-start) - Get productive in 5 minutes
- [Browse Agents](/docs/agents/overview) - Explore all 108 agents
- [Browse Skills](/docs/skills/overview) - Explore all 140 skills

---

<p style={{textAlign: 'center', color: 'var(--ifm-font-color-secondary)'}}>
  Copyright © {new Date().getFullYear()} eSimplicity Inc. All Rights Reserved.
</p>
