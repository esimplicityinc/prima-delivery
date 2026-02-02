---
sidebar_position: 3
title: Best Practices
description: Tips for getting the most out of Prima Delivery
---

# Best Practices

Tips and techniques for effective use of Prima Delivery agents and skills.

## Providing Context

### Include Relevant Code

```
@python-pro Here's my current implementation:

\`\`\`python
def process_data(items):
    result = []
    for item in items:
        if item.is_valid():
            result.append(transform(item))
    return result
\`\`\`

How can I optimize this for large datasets?
```

### Describe Your Environment

```
@kubernetes-architect I need to deploy a Python FastAPI application:

Environment:
- AWS EKS cluster (1.28)
- 3 availability zones
- Expected load: 1000 req/sec
- Database: PostgreSQL RDS

Design a production-ready deployment.
```

### Share Constraints

```
@backend-architect Design an authentication system with these constraints:

- Must support SSO (SAML 2.0)
- No external dependencies for core auth
- Must work offline
- Compliance: SOC2, HIPAA
```

## Choosing the Right Agent

### Task Matching

| Task | Best Agent |
|------|-----------|
| Code optimization | Language-specific pro (e.g., `@python-pro`) |
| System design | `@backend-architect` or `@cloud-architect` |
| Security review | `@security-auditor` |
| Test generation | `@test-automator` |
| Documentation | `@docs-architect` or `@api-documenter` |

### When to Use Specialized Agents

Use specialized agents when you need:
- Deep domain expertise
- Specific framework knowledge
- Industry-standard patterns

```
# For Django-specific questions
@django-pro How do I implement custom user models?

# For general Python
@python-pro How do I optimize this list comprehension?
```

## Effective Prompting

### Be Specific

```
# Too vague
@backend-architect Design an API

# Better
@backend-architect Design a RESTful API for a task management system with:
- CRUD operations for tasks and projects
- User authentication (JWT)
- Team collaboration features
- Pagination and filtering
```

### Request Specific Output

```
@terraform-specialist Create a Terraform module for an S3 bucket with:
- Versioning enabled
- Server-side encryption
- Lifecycle policies for archival
- Output: module code with variables.tf and outputs.tf
```

### Ask for Explanations

```
@rust-pro Explain why this code causes a borrow checker error:

\`\`\`rust
fn main() {
    let s = String::from("hello");
    let r1 = &s;
    let r2 = &mut s;
    println!("{}, {}", r1, r2);
}
\`\`\`
```

## Multi-Turn Conversations

### Build on Previous Responses

```
# Turn 1
@backend-architect Design a user service API

# Turn 2 (after receiving design)
Now add rate limiting to these endpoints

# Turn 3
How should we handle authentication?
```

### Refine Iteratively

```
# Initial request
@test-automator Generate tests for UserService

# Refinement
Add edge cases for null inputs and empty strings

# Further refinement
Include integration tests with the database
```

## Working with Skills

### Explicit Skill Activation

```
@python-pro Using the async-python-patterns skill, implement concurrent API calls to these endpoints
```

### Combining Agent + Skill

```
@backend-architect Apply the api-design-principles skill to design a GraphQL API for this domain model
```

## Performance Tips

### Use Appropriate Model Tiers

- **Opus** agents: Critical decisions, complex architecture
- **Sonnet** agents: Development tasks, debugging
- **Haiku** agents: Quick operations, simple tasks

### Batch Related Requests

Instead of multiple small requests:
```
@python-pro Review function A
@python-pro Review function B
@python-pro Review function C
```

Batch them:
```
@python-pro Review these functions and suggest improvements:

1. Function A: [code]
2. Function B: [code]
3. Function C: [code]
```

## Common Mistakes to Avoid

1. **Too little context** - Always provide relevant code and requirements
2. **Wrong agent** - Match agents to task domains
3. **Vague requests** - Be specific about what you need
4. **Ignoring suggestions** - Review and understand agent recommendations
5. **Not iterating** - Use follow-up questions to refine results

## Next Steps

- [Commands Reference](/docs/usage/commands) - Available commands
- [Agent Overview](/docs/agents/overview) - Browse all agents
- [Skills Overview](/docs/skills/overview) - Browse all skills
