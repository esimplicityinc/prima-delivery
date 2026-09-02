# Instruction forwarding

## When to use

Use this when a delegated agent receives a replacement prompt and therefore
does not automatically inherit the parent agent's instructions.

## AGENTS.md snippet

```markdown
# Instruction forwarding

## Rules

Before delegation, identify the instructions that govern the delegated paths.
Forward the relevant project instructions, directory overrides, and core rules
to the delegated agent. Preserve local precedence: a more specific applicable
instruction remains more specific after forwarding.

Keep the handoff selective. Include only the instructions needed for the bounded
task, along with its requirements, paths, write and tool boundary, validation,
and stop rule. Do not assume that the delegated agent inherited instructions
that were not forwarded.

If required instructions conflict or their precedence cannot be established,
stop and ask for clarification before the delegated work begins.
```
