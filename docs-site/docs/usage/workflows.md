---
sidebar_position: 2
title: Multi-Agent Workflows
description: Pre-configured workflows combining multiple agents
---

# Multi-Agent Workflows

Complex tasks often benefit from combining multiple specialized agents.

## Full-Stack Feature Development

Coordinates 7+ agents for complete feature implementation:

```
@backend-architect → @database-architect → @frontend-developer → 
@test-automator → @security-auditor → @deployment-engineer → @observability-engineer
```

### Example

```
/full-stack-orchestration:full-stack-feature "user authentication with OAuth2"
```

**Flow:**
1. **backend-architect** - Designs API endpoints and authentication flow
2. **database-architect** - Designs user and session schemas
3. **frontend-developer** - Implements login UI and state management
4. **test-automator** - Generates unit and integration tests
5. **security-auditor** - Reviews for security vulnerabilities
6. **deployment-engineer** - Configures CI/CD pipeline
7. **observability-engineer** - Sets up monitoring and alerts

## Security Hardening

Multi-agent security assessment:

```
@security-auditor → @threat-modeling-expert → @code-reviewer
```

### Example

```
/security-scanning:security-hardening --level comprehensive
```

**Includes:**
- Static application security testing (SAST)
- Dependency vulnerability scanning
- Threat modeling
- Code review for security patterns

## Code Review Pipeline

Comprehensive review with multiple perspectives:

```
@code-reviewer → @architect-reviewer → @security-auditor → @performance-engineer
```

### Example

```
/comprehensive-review:full-review
```

**Perspectives:**
- Code quality and best practices
- Architectural consistency
- Security vulnerabilities
- Performance implications

## ML Pipeline Development

End-to-end machine learning workflow:

```
@data-scientist → @ml-engineer → @mlops-engineer → @observability-engineer
```

### Example

```
/machine-learning-ops:ml-pipeline
```

**Flow:**
1. **data-scientist** - Data analysis and feature engineering
2. **ml-engineer** - Model development and training
3. **mlops-engineer** - Pipeline automation and deployment
4. **observability-engineer** - Model monitoring and drift detection

## Incident Response

Production incident management:

```
@incident-responder → @debugger → @devops-troubleshooter → @deployment-engineer
```

### Example

```
/incident-response:smart-fix "memory leak in payment service"
```

**Flow:**
1. **incident-responder** - Assess severity and impact
2. **debugger** - Root cause analysis
3. **devops-troubleshooter** - Implement fix
4. **deployment-engineer** - Deploy hotfix

## Custom Workflows

### Creating Custom Workflows

Combine agents for your specific needs:

```
# Architecture Review Workflow
@architect-reviewer Review the system design
@database-architect Validate the data model
@security-auditor Check for security concerns
@performance-engineer Assess scalability
```

### Sequential Execution

Pass output from one agent to another:

```
# Step 1: Generate code
@python-pro Implement a rate limiter class

# Step 2: Review the implementation  
@code-reviewer Review this code for best practices

# Step 3: Add tests
@test-automator Generate comprehensive tests for this class

# Step 4: Security review
@security-auditor Check for security vulnerabilities
```

## Workflow Patterns

### Planning → Execution

```
Sonnet: architect (design)
  ↓
Haiku: implement (code generation)
  ↓
Haiku: test (test generation)
  ↓
Sonnet: review (quality check)
```

### Reasoning → Action

```
Sonnet: incident-responder (diagnose)
  ↓
Haiku: devops-troubleshooter (fix)
  ↓
Haiku: deployment-engineer (deploy)
```

### Complex → Simple

```
Sonnet: database-architect (design)
  ↓
Haiku: sql-pro (generate migrations)
  ↓
Haiku: database-admin (execute)
```

## Next Steps

- [Best Practices](/docs/usage/best-practices) - Tips for effective workflows
- [Model Tiers](/docs/architecture/model-tiers) - Understanding agent assignments
