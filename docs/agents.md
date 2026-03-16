<p align="center">
  <img src="../prima-deliver-square-trans.png" alt="Prima Delivery" width="80" height="80">
</p>

# Agent Reference

Complete reference for all **108 specialized AI agents** organized by category with model assignments.

## Agent Categories

### Architecture & System Design

#### Core Architecture

| Agent                                                                                         | Model  | Description                                                            |
| --------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------- |
| [backend-architect](../plugins/backend-development/agents/backend-architect.md)               | high   | RESTful API design, microservice boundaries, database schemas          |
| [frontend-developer](../plugins/multi-platform-apps/agents/frontend-developer.md)             | medium | React components, responsive layouts, client-side state management     |
| [graphql-architect](../plugins/backend-development/agents/graphql-architect.md)               | high   | GraphQL schemas, resolvers, federation architecture                    |
| [architect-reviewer](../plugins/comprehensive-review/agents/architect-review.md)              | high   | Architectural consistency analysis and pattern validation              |
| [cloud-architect](../plugins/cloud-infrastructure/agents/cloud-architect.md)                  | high   | AWS/Azure/GCP infrastructure design and cost optimization              |
| [hybrid-cloud-architect](../plugins/cloud-infrastructure/agents/hybrid-cloud-architect.md)    | high   | Multi-cloud strategies across cloud and on-premises environments       |
| [kubernetes-architect](../plugins/kubernetes-operations/agents/kubernetes-architect.md)       | high   | Cloud-native infrastructure with Kubernetes and GitOps                 |
| [service-mesh-expert](../plugins/cloud-infrastructure/agents/service-mesh-expert.md)          | high   | Istio/Linkerd service mesh architecture, mTLS, and traffic management  |
| [event-sourcing-architect](../plugins/backend-development/agents/event-sourcing-architect.md) | high   | Event sourcing, CQRS patterns, event stores, and saga orchestration    |
| [monorepo-architect](../plugins/developer-essentials/agents/monorepo-architect.md)            | high   | Monorepo tooling with Nx, Turborepo, Bazel, and workspace optimization |

#### UI/UX & Mobile

| Agent                                                                                    | Model  | Description                                             |
| ---------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------- |
| [ui-designer](../plugins/ui-design/agents/ui-designer.md)                                | high   | UI/UX design for mobile and web with modern patterns    |
| [accessibility-expert](../plugins/ui-design/agents/accessibility-expert.md)              | high   | WCAG compliance, accessibility audits, inclusive design |
| [design-system-architect](../plugins/ui-design/agents/design-system-architect.md)        | high   | Design tokens, component libraries, theming systems     |
| [ui-ux-designer](../plugins/multi-platform-apps/agents/ui-ux-designer.md)                | medium | Interface design, wireframes, design systems            |
| [ui-visual-validator](../plugins/accessibility-compliance/agents/ui-visual-validator.md) | medium | Visual regression testing and UI verification           |
| [mobile-developer](../plugins/multi-platform-apps/agents/mobile-developer.md)            | medium | React Native and Flutter application development        |
| [ios-developer](../plugins/multi-platform-apps/agents/ios-developer.md)                  | medium | Native iOS development with Swift/SwiftUI               |
| [flutter-expert](../plugins/multi-platform-apps/agents/flutter-expert.md)                | medium | Advanced Flutter development with state management      |

### Programming Languages

#### Systems & Low-Level

| Agent                                                             | Model  | Description                                                 |
| ----------------------------------------------------------------- | ------ | ----------------------------------------------------------- |
| [c-pro](../plugins/systems-programming/agents/c-pro.md)           | medium | System programming with memory management and OS interfaces |
| [cpp-pro](../plugins/systems-programming/agents/cpp-pro.md)       | medium | Modern C++ with RAII, smart pointers, STL algorithms        |
| [rust-pro](../plugins/systems-programming/agents/rust-pro.md)     | medium | Memory-safe systems programming with ownership patterns     |
| [golang-pro](../plugins/systems-programming/agents/golang-pro.md) | medium | Concurrent programming with goroutines and channels         |

#### Web & Application

| Agent                                                                               | Model  | Description                                                                       |
| ----------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------- |
| [javascript-pro](../plugins/javascript-typescript/agents/javascript-pro.md)         | medium | Modern JavaScript with ES6+, async patterns, Node.js                              |
| [typescript-pro](../plugins/javascript-typescript/agents/typescript-pro.md)         | medium | Advanced TypeScript with type systems and generics                                |
| [python-pro](../plugins/python-development/agents/python-pro.md)                    | medium | Python development with advanced features and optimization                        |
| [temporal-python-pro](../plugins/backend-development/agents/temporal-python-pro.md) | medium | Temporal workflow orchestration with Python SDK, durable workflows, saga patterns |
| [ruby-pro](../plugins/web-scripting/agents/ruby-pro.md)                             | medium | Ruby with metaprogramming, Rails patterns, gem development                        |
| [php-pro](../plugins/web-scripting/agents/php-pro.md)                               | medium | Modern PHP with frameworks and performance optimization                           |

#### Enterprise & JVM

| Agent                                                       | Model  | Description                                                          |
| ----------------------------------------------------------- | ------ | -------------------------------------------------------------------- |
| [java-pro](../plugins/jvm-languages/agents/java-pro.md)     | medium | Modern Java with streams, concurrency, JVM optimization              |
| [scala-pro](../plugins/jvm-languages/agents/scala-pro.md)   | medium | Enterprise Scala with functional programming and distributed systems |
| [csharp-pro](../plugins/jvm-languages/agents/csharp-pro.md) | medium | C# development with .NET frameworks and patterns                     |

#### Specialized Platforms

| Agent                                                                              | Model  | Description                                                                               |
| ---------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------- |
| [elixir-pro](../plugins/functional-programming/agents/elixir-pro.md)               | medium | Elixir with OTP patterns and Phoenix frameworks                                           |
| [django-pro](../plugins/api-scaffolding/agents/django-pro.md)                      | medium | Django development with ORM and async views                                               |
| [fastapi-pro](../plugins/api-scaffolding/agents/fastapi-pro.md)                    | medium | FastAPI with async patterns and Pydantic                                                  |
| [haskell-pro](../plugins/functional-programming/agents/haskell-pro.md)             | medium | Strongly typed functional programming with purity, advanced type systems, and concurrency |
| [unity-developer](../plugins/game-development/agents/unity-developer.md)           | medium | Unity game development and optimization                                                   |
| [minecraft-bukkit-pro](../plugins/game-development/agents/minecraft-bukkit-pro.md) | medium | Minecraft server plugin development                                                       |
| [sql-pro](../plugins/database-design/agents/sql-pro.md)                            | medium | Complex SQL queries and database optimization                                             |

### Infrastructure & Operations

#### DevOps & Deployment

| Agent                                                                                  | Model  | Description                                                        |
| -------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------ |
| [devops-troubleshooter](../plugins/incident-response/agents/devops-troubleshooter.md)  | medium | Production debugging, log analysis, deployment troubleshooting     |
| [deployment-engineer](../plugins/cloud-infrastructure/agents/deployment-engineer.md)   | medium | CI/CD pipelines, containerization, cloud deployments               |
| [terraform-specialist](../plugins/cloud-infrastructure/agents/terraform-specialist.md) | medium | Infrastructure as Code with Terraform modules and state management |
| [dx-optimizer](../plugins/team-collaboration/agents/dx-optimizer.md)                   | medium | Developer experience optimization and tooling improvements         |

#### Database Management

| Agent                                                                                  | Model  | Description                                                         |
| -------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------- |
| [database-optimizer](../plugins/observability-monitoring/agents/database-optimizer.md) | medium | Query optimization, index design, migration strategies              |
| [database-admin](../plugins/database-migrations/agents/database-admin.md)              | medium | Database operations, backup, replication, monitoring                |
| [database-architect](../plugins/database-design/agents/database-architect.md)          | high   | Database design from scratch, technology selection, schema modeling |

#### Incident Response & Network

| Agent                                                                              | Model  | Description                                         |
| ---------------------------------------------------------------------------------- | ------ | --------------------------------------------------- |
| [incident-responder](../plugins/incident-response/agents/incident-responder.md)    | high   | Production incident management and resolution       |
| [network-engineer](../plugins/observability-monitoring/agents/network-engineer.md) | medium | Network debugging, load balancing, traffic analysis |

#### Project Management

| Agent                                                             | Model | Description                                                                          |
| ----------------------------------------------------------------- | ----- | ------------------------------------------------------------------------------------ |
| [conductor-validator](../conductor/agents/conductor-validator.md) | high  | Validates Conductor project artifacts for completeness, consistency, and correctness |

### Quality Assurance & Security

#### Code Quality & Review

| Agent                                                                                            | Model | Description                                                     |
| ------------------------------------------------------------------------------------------------ | ----- | --------------------------------------------------------------- |
| [code-reviewer](../plugins/comprehensive-review/agents/code-reviewer.md)                         | high  | Code review with security focus and production reliability      |
| [security-auditor](../plugins/comprehensive-review/agents/security-auditor.md)                   | high  | Vulnerability assessment and OWASP compliance                   |
| [backend-security-coder](../plugins/data-validation-suite/agents/backend-security-coder.md)      | high  | Secure backend coding practices, API security implementation    |
| [frontend-security-coder](../plugins/frontend-mobile-security/agents/frontend-security-coder.md) | high  | XSS prevention, CSP implementation, client-side security        |
| [mobile-security-coder](../plugins/frontend-mobile-security/agents/mobile-security-coder.md)     | high  | Mobile security patterns, WebView security, biometric auth      |
| [threat-modeling-expert](../plugins/security-scanning/agents/threat-modeling-expert.md)          | high  | STRIDE threat modeling, attack trees, and security requirements |

#### Testing & Debugging

| Agent                                                                         | Model  | Description                                                |
| ----------------------------------------------------------------------------- | ------ | ---------------------------------------------------------- |
| [test-automator](../plugins/codebase-cleanup/agents/test-automator.md)        | medium | Comprehensive test suite creation (unit, integration, e2e) |
| [tdd-orchestrator](../plugins/backend-development/agents/tdd-orchestrator.md) | medium | Test-Driven Development methodology guidance               |
| [debugger](../plugins/error-debugging/agents/debugger.md)                     | medium | Error resolution and test failure analysis                 |
| [error-detective](../plugins/error-debugging/agents/error-detective.md)       | medium | Log analysis and error pattern recognition                 |

#### Performance & Observability

| Agent                                                                                          | Model | Description                                                    |
| ---------------------------------------------------------------------------------------------- | ----- | -------------------------------------------------------------- |
| [performance-engineer](../plugins/observability-monitoring/agents/performance-engineer.md)     | high  | Application profiling and optimization                         |
| [observability-engineer](../plugins/observability-monitoring/agents/observability-engineer.md) | high  | Production monitoring, distributed tracing, SLI/SLO management |
| [search-specialist](../plugins/content-marketing/agents/search-specialist.md)                  | low   | Advanced web research and information synthesis                |

### Data & AI

#### Data Engineering & Analytics

| Agent                                                                      | Model  | Description                                             |
| -------------------------------------------------------------------------- | ------ | ------------------------------------------------------- |
| [data-scientist](../plugins/machine-learning-ops/agents/data-scientist.md) | high   | Data analysis, SQL queries, BigQuery operations         |
| [data-engineer](../plugins/data-engineering/agents/data-engineer.md)       | medium | ETL pipelines, data warehouses, streaming architectures |

#### Machine Learning & AI

| Agent                                                                                         | Model | Description                                                           |
| --------------------------------------------------------------------------------------------- | ----- | --------------------------------------------------------------------- |
| [ai-engineer](../plugins/llm-application-dev/agents/ai-engineer.md)                           | high  | LLM applications, RAG systems, prompt pipelines                       |
| [ml-engineer](../plugins/machine-learning-ops/agents/ml-engineer.md)                          | high  | ML pipelines, model serving, feature engineering                      |
| [mlops-engineer](../plugins/machine-learning-ops/agents/mlops-engineer.md)                    | high  | ML infrastructure, experiment tracking, model registries              |
| [prompt-engineer](../plugins/llm-application-dev/agents/prompt-engineer.md)                   | high  | LLM prompt optimization and engineering                               |
| [vector-database-engineer](../plugins/llm-application-dev/agents/vector-database-engineer.md) | high  | Vector databases, embeddings, similarity search, and hybrid retrieval |

### Documentation & Technical Writing

| Agent                                                                                | Model  | Description                                                           |
| ------------------------------------------------------------------------------------ | ------ | --------------------------------------------------------------------- |
| [docs-architect](../plugins/code-documentation/agents/docs-architect.md)             | high   | Comprehensive technical documentation generation                      |
| [api-documenter](../plugins/api-testing-observability/agents/api-documenter.md)      | medium | OpenAPI/Swagger specifications and developer docs                     |
| [reference-builder](../plugins/documentation-generation/agents/reference-builder.md) | low    | Technical references and API documentation                            |
| [tutorial-engineer](../plugins/code-documentation/agents/tutorial-engineer.md)       | medium | Step-by-step tutorials and educational content                        |
| [mermaid-expert](../plugins/documentation-generation/agents/mermaid-expert.md)       | medium | Diagram creation (flowcharts, sequences, ERDs)                        |
| [c4-code](../plugins/c4-architecture/agents/c4-code.md)                              | low    | C4 Code-level documentation with function signatures and dependencies |
| [c4-component](../plugins/c4-architecture/agents/c4-component.md)                    | medium | C4 Component-level architecture synthesis and documentation           |
| [c4-container](../plugins/c4-architecture/agents/c4-container.md)                    | medium | C4 Container-level architecture with API documentation                |
| [c4-context](../plugins/c4-architecture/agents/c4-context.md)                        | medium | C4 Context-level system documentation with personas and user journeys |

### Business & Operations

#### Business Analysis & Finance

| Agent                                                                        | Model  | Description                                             |
| ---------------------------------------------------------------------------- | ------ | ------------------------------------------------------- |
| [business-analyst](../plugins/business-analytics/agents/business-analyst.md) | medium | Metrics analysis, reporting, KPI tracking               |
| [quant-analyst](../plugins/quantitative-trading/agents/quant-analyst.md)     | high   | Financial modeling, trading strategies, market analysis |
| [risk-manager](../plugins/quantitative-trading/agents/risk-manager.md)       | medium | Portfolio risk monitoring and management                |

#### Marketing & Sales

| Agent                                                                             | Model  | Description                                  |
| --------------------------------------------------------------------------------- | ------ | -------------------------------------------- |
| [content-marketer](../plugins/content-marketing/agents/content-marketer.md)       | medium | Blog posts, social media, email campaigns    |
| [sales-automator](../plugins/customer-sales-automation/agents/sales-automator.md) | low    | Cold emails, follow-ups, proposal generation |

#### Support & Legal

| Agent                                                                               | Model  | Description                                             |
| ----------------------------------------------------------------------------------- | ------ | ------------------------------------------------------- |
| [customer-support](../plugins/customer-sales-automation/agents/customer-support.md) | medium | Support tickets, FAQ responses, customer communication  |
| [hr-pro](../plugins/hr-legal-compliance/agents/hr-pro.md)                           | high   | HR operations, policies, employee relations             |
| [legal-advisor](../plugins/hr-legal-compliance/agents/legal-advisor.md)             | high   | Privacy policies, terms of service, legal documentation |

### SEO & Content Optimization

| Agent                                                                                                     | Model  | Description                                          |
| --------------------------------------------------------------------------------------------------------- | ------ | ---------------------------------------------------- |
| [seo-content-auditor](../plugins/seo-content-creation/agents/seo-content-auditor.md)                      | medium | Content quality analysis, E-E-A-T signals assessment |
| [seo-meta-optimizer](../plugins/seo-technical-optimization/agents/seo-meta-optimizer.md)                  | low    | Meta title and description optimization              |
| [seo-keyword-strategist](../plugins/seo-technical-optimization/agents/seo-keyword-strategist.md)          | low    | Keyword analysis and semantic variations             |
| [seo-structure-architect](../plugins/seo-technical-optimization/agents/seo-structure-architect.md)        | low    | Content structure and schema markup                  |
| [seo-snippet-hunter](../plugins/seo-technical-optimization/agents/seo-snippet-hunter.md)                  | low    | Featured snippet formatting                          |
| [seo-content-refresher](../plugins/seo-analysis-monitoring/agents/seo-content-refresher.md)               | low    | Content freshness analysis                           |
| [seo-cannibalization-detector](../plugins/seo-analysis-monitoring/agents/seo-cannibalization-detector.md) | low    | Keyword overlap detection                            |
| [seo-authority-builder](../plugins/seo-analysis-monitoring/agents/seo-authority-builder.md)               | medium | E-E-A-T signal analysis                              |
| [seo-content-writer](../plugins/seo-content-creation/agents/seo-content-writer.md)                        | medium | SEO-optimized content creation                       |
| [seo-content-planner](../plugins/seo-content-creation/agents/seo-content-planner.md)                      | low    | Content planning and topic clusters                  |

### Specialized Domains

| Agent                                                                                   | Model  | Description                                             |
| --------------------------------------------------------------------------------------- | ------ | ------------------------------------------------------- |
| [arm-cortex-expert](../plugins/arm-cortex-microcontrollers/agents/arm-cortex-expert.md) | medium | ARM Cortex-M firmware and peripheral driver development |
| [blockchain-developer](../plugins/blockchain-web3/agents/blockchain-developer.md)       | medium | Web3 apps, smart contracts, DeFi protocols              |
| [payment-integration](../plugins/payment-processing/agents/payment-integration.md)      | medium | Payment processor integration (Stripe, PayPal)          |
| [legacy-modernizer](../plugins/framework-migration/agents/legacy-modernizer.md)         | medium | Legacy code refactoring and modernization               |
| [context-manager](../plugins/agent-orchestration/agents/context-manager.md)             | low    | Multi-agent context management                          |

## Model Configuration

Agents are assigned to model tiers based on task complexity and computational requirements.

### Model Distribution Summary

| Model  | Agent Count | Use Case                                                        |
| ------ | ----------- | --------------------------------------------------------------- |
| High   | 42          | Critical architecture, security, code review, production coding |
| Medium | 39          | Complex tasks, support with intelligence                        |
| Low    | 18          | Fast operational tasks                                          |

### Model Selection Criteria

#### Low - Fast Execution & Deterministic Tasks

**Use when:**

- Generating code from well-defined specifications
- Creating tests following established patterns
- Writing documentation with clear templates
- Executing infrastructure operations
- Performing database query optimization
- Handling customer support responses
- Processing SEO optimization tasks
- Managing deployment pipelines

#### Medium - Complex Reasoning & Architecture

**Use when:**

- Designing system architecture
- Making technology selection decisions
- Performing security audits
- Reviewing code for architectural patterns
- Creating complex AI/ML pipelines
- Providing language-specific expertise
- Orchestrating multi-agent workflows
- Handling business-critical legal/HR matters

### Hybrid Orchestration Patterns

The plugin ecosystem leverages Medium + Low orchestration for optimal performance and cost efficiency:

#### Pattern 1: Planning → Execution

```
Medium: backend-architect (design API architecture)
  ↓
Low: Generate API endpoints following spec
  ↓
Low: test-automator (generate comprehensive tests)
  ↓
Medium: code-reviewer (architectural review)
```

#### Pattern 2: Reasoning → Action (Incident Response)

```
Medium: incident-responder (diagnose issue, create strategy)
  ↓
Low: devops-troubleshooter (execute fixes)
  ↓
Low: deployment-engineer (deploy hotfix)
  ↓
Low: Implement monitoring alerts
```

#### Pattern 3: Complex → Simple (Database Design)

```
Medium: database-architect (schema design, technology selection)
  ↓
Low: sql-pro (generate migration scripts)
  ↓
Low: database-admin (execute migrations)
  ↓
Low: database-optimizer (tune query performance)
```

#### Pattern 4: Multi-Agent Workflows

```
Full-Stack Feature Development:
Medium: backend-architect + frontend-developer (design components)
  ↓
Low: Generate code following designs
  ↓
Low: test-automator (unit + integration tests)
  ↓
Medium: security-auditor (security review)
  ↓
Low: deployment-engineer (CI/CD setup)
  ↓
Low: Setup observability stack
```

## Agent Invocation

### @workspace (Copilot)

In GitHub Copilot Chat, invoke agents via `@workspace` with natural language:

```
@workspace Use python-pro to review this code for performance issues
@workspace Have backend-architect design the authentication API
@workspace Get security-auditor to scan for OWASP vulnerabilities
```

### Natural Language

Agents can be invoked through natural language when you need the AI to reason about which specialist to use:

```
"Use backend-architect to design the authentication API"
"Have security-auditor scan for OWASP vulnerabilities"
"Get performance-engineer to optimize this database query"
```

### Slash Commands

Many agents are accessible through plugin slash commands for direct invocation:

```bash
/backend-development:feature-development user authentication
/security-scanning:security-sast
/incident-response:smart-fix "memory leak in payment service"
```

## Contributing

To add a new agent:

1. Create `plugins/{plugin-name}/agents/{agent-name}.md`
2. Add frontmatter with name, description, and model assignment
3. Write comprehensive system prompt
4. Update plugin definition in `.claude-plugin/marketplace.json`
5. Verify the Copilot agent output is generated at `.github/agents/`

See [Contributing Guide](../CONTRIBUTING.md) for details.
