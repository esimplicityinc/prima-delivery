# Design and error handling

## When to use

Use this for implementation or review work that changes production behavior. It
sets design constraints and makes unsupported or unsafe states explicit.

## AGENTS.md snippet

```markdown
# Design and error handling

## Design constraints

Prefer small, cohesive modules with clear boundaries, narrow interfaces, and
direct control flow. Design for known requirements and likely near-term changes
by keeping entry points stable and logic isolated.

Treat a file around 300 lines as a review trigger: consider splitting it, but do
not split mechanically when a framework, generated artifact, migration, fixture,
schema, or test structure is better kept together.

Do not expand a production API only to support tests; prefer test-local helpers
or explicit test seams. Prefer existing well-maintained libraries when they
reduce risk. Ask before adding a major dependency, service, paid tool, or
architectural commitment. Design user-facing UI around user tasks and workflows,
not internal schemas or storage models.

### KISS — Keep it simple

- Prefer straightforward control flow over clever meta-programming.
- Prefer explicit branches and typed or well-defined interfaces over hidden
  dynamic behavior.
- Keep error paths obvious and localized.

### YAGNI — You aren't gonna need it

- Do not add configuration keys, interface methods, feature flags, dependency
  layers, or workflow branches without a concrete accepted use case.
- Do not introduce a speculative abstraction without at least one current
  caller.
- Keep unsupported paths explicit: return an error rather than adding partial
  fake support.

### DRY — Rule of three

- Duplicate small, local logic when it preserves clarity.
- Extract a shared utility only after the same pattern appears repeatedly and
  has stabilized.
- Preserve module boundaries and avoid hidden coupling when extracting.

### SRP + ISP — Single responsibility + interface segregation

- Keep each module, package, component, service, or script focused on one
  concern.
- Use existing narrow interfaces or extension points when the project provides
  them.
- Avoid fat interfaces and modules that mix policy, transport, storage,
  presentation, and orchestration.
- Do not add unrelated methods to an existing interface. Define a narrower
  interface or a separate module when needed.

## Failure handling

- Fail fast with explicit errors for unsupported, unsafe, or inconsistent
  states.
- Do not add silent or implicit fallbacks that hide missing configuration,
  service failures, permission problems, unavailable capabilities, or invalid
  state.
- An intentional fallback must be explicit, safe, documented, observable, and
  tested.
- Do not leave empty exception handlers, including `catch`, `except`, `rescue`,
  or equivalent error-swallowing constructs.
- Never silently broaden permissions or capabilities.
```
