# Workflow controls

## When to use

Use this only when the runtime has configured multi-agent workflows. It sets the
conditions for choosing a workflow; it does not make workflows mandatory.

## AGENTS.md snippet

```markdown
# Workflow controls

## Rules

Use a workflow only after explicit requester opt-in. A request for a workflow,
multi-agent orchestration or fan-out, or a named or saved workflow is opt-in.
When opt-in exists, use named workflows where they are beneficial.

Choose a workflow only when it is more reliable than direct work or a small set
of named calls, such as for:

- runtime-discovered fan-out;
- dependent staged work;
- independent verification; or
- executable repair gates.

Each workflow call must declare its bounded item, stage, and repair scope.
Prefer pipelines for independently staged items. Use complete-result parallel
collection only when a later stage needs every result. Filter failed or skipped
results, and use structured outputs when later stages consume them.

Do not use a workflow for trivial work or for a few named, independent tasks.

## Retry limit

Limit repair or debugging loops to three materially distinct failed attempts.
Stop immediately when the same blocker recurs. Report the failed approaches,
evidence, exact blocker, and next decision instead of retrying indefinitely.
```
