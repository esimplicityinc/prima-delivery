# Secrets and sensitive data

## When to use

Use this whenever repository files, commands, delegated work, or displayed
output could include sensitive values. This module is safe to include by default
when the risk is unknown.

## AGENTS.md snippet

```markdown
# Secrets and sensitive data

## Rules

- Never print secrets, tokens, private keys, credentials, cookies, or sensitive
  environment values.
- Do not ask requesters to paste secrets.
- Do not use commands that broadly dump sensitive state, such as a complete
  environment dump or a private-key file read.
- Prefer existing authenticated CLIs, credential stores, or environment-specific
  secret mechanisms.
- Redact sensitive strings in displayed output.
- Do not pass sensitive values to delegated agents unless the task and the
  agent's permitted tools require them; use the minimum necessary scope.

If the required action changes accounts, authentication, security, or privacy,
obtain explicit requester authorization before acting. Never silently broaden
permissions or capabilities.
```
