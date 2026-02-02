---
sidebar_position: 1
title: Commands Reference
description: Complete reference for slash commands and agent invocations
---

# Commands Reference

Complete reference for using Prima Delivery agents and commands.

## Agent Invocation

### OpenCode Syntax

```
@agent-name [your request]
```

Examples:
```
@python-pro Review this function for performance issues

@backend-architect Design a REST API for user authentication

@security-auditor Scan this code for vulnerabilities
```

### Claude Code Syntax

```
Use [agent-name] to [task description]
```

Examples:
```
Use python-pro to optimize this database query

Have backend-architect design a microservices architecture

Get security-auditor to review this authentication code
```

## Slash Commands by Category

### Development

| Command | Description |
|---------|-------------|
| `/backend-development:feature-development` | End-to-end backend feature |
| `/full-stack-orchestration:full-stack-feature` | Complete full-stack implementation |
| `/multi-platform-apps:multi-platform` | Cross-platform development |

### Testing

| Command | Description |
|---------|-------------|
| `/unit-testing:test-generate` | Generate comprehensive unit tests |
| `/tdd-workflows:tdd-cycle` | Complete TDD cycle |
| `/tdd-workflows:tdd-red` | Write failing tests |
| `/tdd-workflows:tdd-green` | Implement to pass tests |
| `/tdd-workflows:tdd-refactor` | Refactor with passing tests |

### Code Quality

| Command | Description |
|---------|-------------|
| `/code-review-ai:ai-review` | AI-powered code review |
| `/comprehensive-review:full-review` | Multi-perspective analysis |
| `/comprehensive-review:pr-enhance` | Enhance pull requests |

### Debugging

| Command | Description |
|---------|-------------|
| `/debugging-toolkit:smart-debug` | Interactive debugging |
| `/incident-response:incident-response` | Production incident management |
| `/incident-response:smart-fix` | Automated resolution |
| `/error-debugging:error-analysis` | Deep error analysis |
| `/distributed-debugging:debug-trace` | Distributed tracing |

### Security

| Command | Description |
|---------|-------------|
| `/security-scanning:security-hardening` | Comprehensive hardening |
| `/security-scanning:security-sast` | Static analysis |
| `/security-scanning:security-dependencies` | Dependency scanning |
| `/security-compliance:compliance-check` | SOC2/HIPAA/GDPR |

### Infrastructure

| Command | Description |
|---------|-------------|
| `/kubernetes-operations:k8s-deploy` | Kubernetes deployment |
| `/cloud-infrastructure:terraform-plan` | Infrastructure planning |
| `/cicd-automation:pipeline-setup` | CI/CD configuration |

### Documentation

| Command | Description |
|---------|-------------|
| `/code-documentation:generate-docs` | Auto-generate docs |
| `/documentation-generation:api-docs` | API documentation |
| `/c4-architecture:c4-diagram` | Architecture diagrams |

### Data & AI

| Command | Description |
|---------|-------------|
| `/machine-learning-ops:ml-pipeline` | ML pipeline setup |
| `/llm-application-dev:langchain-agent` | LangChain agent creation |
| `/llm-application-dev:prompt-optimize` | Prompt optimization |

## Command Patterns

### Chaining Commands

Execute multiple commands in sequence:

```
/security-scanning:security-sast
# Review results, then:
/security-scanning:security-hardening --level comprehensive
```

### Passing Arguments

```
/backend-development:feature-development user-authentication --with-oauth2

/unit-testing:test-generate --coverage 90 --framework pytest
```

### Using with Context

```
# First, provide context
Here's my current implementation:
[paste code]

# Then invoke command
/code-review-ai:ai-review
```

## Best Practices

1. **Provide context** - Share relevant code and requirements
2. **Be specific** - Describe exactly what you need
3. **Use appropriate agents** - Match agents to tasks
4. **Chain effectively** - Combine commands for complex workflows
5. **Review outputs** - Validate agent suggestions before applying

## Next Steps

- [Workflows](/docs/usage/workflows) - Multi-agent workflow examples
- [Best Practices](/docs/usage/best-practices) - Tips for effective usage
