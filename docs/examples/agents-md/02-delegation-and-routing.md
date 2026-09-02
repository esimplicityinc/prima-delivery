# Delegation and routing

## When to use

Use this when the runtime can delegate work to named roles. Keep the work local
when it is trivial and fully scoped.

## AGENTS.md snippet

```markdown
# Delegation and routing

## Delegation safety

Every delegation must include a bounded envelope:

- objective and accepted requirements;
- relevant paths, current state, and applicable instruction paths;
- write and tool boundary;
- acceptance criteria and required validation;
- stop or escalation rule; and
- required output.

Do not duplicate concurrent work. Use one primary implementer and, by default,
at most one independent review layer. Fan out only independent, conflict-free
items, and stage work with real dependencies.

The parent owns independent acceptance review. Retrieve and read each complete
background-agent result before synthesis; a completion preview is not enough.

Require explicit requester authorization before purchases, destructive or
irreversible operations, production-control actions, or account,
authentication, security, or privacy changes. Delegating the task does not grant
that authorization. Tool-layer restrictions remain authoritative.

## Routing

| Need | Route |
| --- | --- |
| Trivial, fully scoped edit | Main agent directly |
| Local repository discovery | `explore` |
| Current external or library research | `librarian` |
| Multi-file or sequenced implementation plan | `plan` |
| Architecture decision or unresolved root cause | `oracle` |
| UI/UX or visual implementation | `designer` |
| Bounded implementation | `fixer` |
| Cross-module or correctness-critical work, or failed `fixer` | `fixer-high` |
| Failed `fixer-high` or exceptional correctness risk | `fixer-max` |
| Small, bounded artifact review | `quick-review` |
| Broad artifact conformance review or large plan review | `reviewer` |
| Validated reader-visible change | `doc-updater` |
| New or substantial documentation | `doc-author` |

Fixers may use only their configured bounded support. Do not request a separate
`doc-updater` pass when the implementer has already updated and verified the
documentation.
```
