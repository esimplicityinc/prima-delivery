# Delivery baseline

## When to use

Use this as the starting point for an agent that changes a repository. It covers
planning, verification, test failures, and the final handoff without assuming
that delegation or workflows are available.

## AGENTS.md snippet

```markdown
# Delivery baseline

## Rules

- Before non-trivial implementation, state material assumptions.
- Keep the work focused on the accepted requirements. Do not speculate about
  missing requirements or add unrelated changes.
- Consider failure modes, edge cases, security, and maintainability; do not
  handle only the happy path.
- Verify actual edits and command output, not a summary of what was done.
- Do not claim correctness unless verification supports the claim. Report both
  checks run and checks not run.

## Test failures

When a test fails, determine the root cause before changing code.

- Treat production code as suspect until evidence rules it out.
- Do not weaken assertions, broaden matchers, delete coverage, or add
  `skip`, `xfail`, or `todo` markers merely to pass.
- If a test is incorrect, explain the inaccurate assertion and why its
  replacement is more accurate.
- Add regression coverage for a confirmed defect when it is appropriate to the
  change.

## Final handoff

Report the changed files, the verification performed and its result, and any
remaining limitation, failure, or decision needed from the requester.
```
