# AGENTS.md examples

Copy-ready instruction modules for an agent that works in a repository. Each
example keeps its usage guidance outside the fenced `markdown` block. The block
itself is valid `AGENTS.md` content that can be copied as-is. Choose only the
rules that match the agent runtime and the work being performed; do not add a
module merely because it might be useful later.

## Composition order

Start with [`01-delivery-baseline.md`](01-delivery-baseline.md). Add the other
modules in numeric order when their conditions apply:

1. [`02-delegation-and-routing.md`](02-delegation-and-routing.md) — delegates
   work to named roles.
2. [`03-workflow-controls.md`](03-workflow-controls.md) — uses configured
   multi-agent workflows.
3. [`04-instruction-forwarding.md`](04-instruction-forwarding.md) — delegates
   to agents whose prompts replace, rather than inherit, parent instructions.
4. [`05-research-and-sourcing.md`](05-research-and-sourcing.md) — relies on
   current, unfamiliar, version-sensitive, or security-sensitive information.
5. [`06-secrets-and-sensitive-data.md`](06-secrets-and-sensitive-data.md) —
   handles repositories, tools, or output that could contain sensitive values.
6. [`07-design-and-error-handling.md`](07-design-and-error-handling.md) —
   implements or reviews production changes.

When more than one module applies, copy the contents of each `AGENTS.md` snippet,
keep their headings, and merge them without rewriting a rule to weaken another.
Repository- or directory-specific instructions should retain their local
precedence.

## Trade-offs

These modules favor explicit limits and observable decisions over autonomous
breadth. Delegation requires a bounded handoff and a separate acceptance check,
which can cost an extra step but prevents overlapping work and unreviewed
claims. Workflow use is opt-in and retry loops are limited; a repeated blocker
is reported instead of being retried indefinitely. Research rules add sourcing
work only when the information is likely to be stale or consequential.

The examples deliberately do not define commands, agent availability, project
paths, or credentials. Add those only where the repository and runtime verify
them.

## Coverage

| Source concern | Example |
| --- | --- |
| Assumptions, verification, test failures, and reports | [01](01-delivery-baseline.md) |
| Bounded delegation, authorization, and routing | [02](02-delegation-and-routing.md) |
| Workflow opt-in, stages, and bounded retries | [03](03-workflow-controls.md) |
| Prompt replacement and instruction forwarding | [04](04-instruction-forwarding.md) |
| Primary sources and unverified conclusions | [05](05-research-and-sourcing.md) |
| Secret and sensitive-data safety | [06](06-secrets-and-sensitive-data.md) |
| Design principles and explicit failure handling | [07](07-design-and-error-handling.md) |
