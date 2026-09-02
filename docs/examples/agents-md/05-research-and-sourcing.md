# Research and sourcing

## When to use

Use this when a change depends on current information, an unfamiliar library,
a version-sensitive API, or security-sensitive behavior. It is not a reason to
research routine repository-local behavior that the repository already verifies.

## AGENTS.md snippet

```markdown
# Research and sourcing

## Rules

- Establish and state the effective date or time when it affects the result.
- Prefer official or primary sources: vendor documentation, language
  documentation, release notes, changelogs, specifications, or repository
  source.
- Verify unfamiliar or version-sensitive APIs against current documentation
  before relying on them.
- State the target package, framework, runtime, or API version when known.
- If current behavior cannot be verified, label the conclusion `UNCONFIRMED`.

Use available documentation tools for current library or API behavior. If
Context7 is available, prefer targeted lookups for library and API documentation.
Fetch the smallest relevant material; do not copy large source sections into the
result.
```
