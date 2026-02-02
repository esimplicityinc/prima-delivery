# Contributing to Prima Delivery

Internal contribution guidelines for the Prima Team.

## Getting Started

1. Clone the repository
2. Install dependencies: `bun install`
3. Review existing agents and skills

## Adding New Agents

1. Create a new markdown file in `.opencode/agents/` or `plugins/{plugin}/agents/`
2. Include YAML frontmatter with:
   - `description`: Clear description of the agent's purpose
   - `mode`: `subagent` (default) or `primary`
   - `model`: Target model (opus/sonnet/haiku)
3. Write comprehensive system prompt
4. Run validation: `bun run validate`

## Adding New Skills

1. Create a directory in `.opencode/skills/{skill-name}/`
2. Add `SKILL.md` with:
   - `name`: Lowercase, hyphen-separated identifier
   - `description`: Include "Use when..." activation criteria
3. Add any reference files in `references/` subdirectory

## Testing Changes

```bash
# Validate all skills
bun run validate

# Rebuild OpenCode configuration
bun run build
```

## Code Review

All changes require review before merging. Include:

- Clear description of changes
- Testing performed
- Any breaking changes noted

## Questions

Contact the Prima Team lead for guidance on contributions.
