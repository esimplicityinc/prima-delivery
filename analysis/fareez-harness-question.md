In https://github.com/esimplicityinc/prima-delivery/pull/2 Fareez noted

## Reviewer note: approach tradeoffs (opencode-native vs. alternatives)

Dropping a note here to make the architectural choice explicit, since this PR roughly doubles the depth of our investment in opencode (117 agents, ~720-line `opencode.json`, plus two meta-agents whose entire job is to author more opencode-shaped files). Worth being deliberate about it.

### What this PR commits us to

- Agent definition format: opencode-flavored markdown frontmatter (`mode: subagent`, `tools: {write, edit, question, ...}`, `temperature`, model tiers `high|medium|low`).
- Dispatch model: `@agent-name` invocation and `permission.task` — opencode runtime features, not portable.
- Storage: `.opencode/agents/*.md` + central registration in `opencode.json`.
- Meta-tooling: `agent-maker` and `agent-modifier` themselves emit opencode-shaped files, so every future agent created through this wizard inherits the same coupling.

Net effect: agents, the tool that creates agents, and the tool that fixes agents all assume opencode is the host. That's not necessarily wrong — it's just worth naming.

### The alternatives, and what they actually are

| Option | What it is | Where it fits | Where it doesn't |
|---|---|---|---|
| **opencode-native (this PR)** | Editor-side agent runtime; markdown + JSON config | Developer-facing automation, code review, scaffolding, doc gen — i.e. things humans invoke from an IDE/CLI session | Production runtime inside a deployed app; running outside an opencode session |
| **Vercel AI SDK** | Node/TS SDK for LLM calls, tool-calling, streaming, agent loops in application code | A Next.js / Elysia / Lambda service that needs to call models from product code | Editor-side, multi-agent dispatch with human-in-the-loop, file-based prompt management |
| **AWS Bedrock (Agents / Knowledge Bases)** | Managed multi-agent + RAG service inside AWS | Customer-facing agentic features in a govcloud/AWS posture, with IAM, audit, data residency baked in | Anything inside the developer's editor; iteration speed is slow vs. editing a markdown file |
| **Custom scaffolding (runtime-agnostic spec)** | YAML/JSON spec for agents + thin adapters to whatever runtime (opencode today, something else tomorrow) | If we expect to switch runtimes, or run the same agent both editor-side and in product code | Adds an abstraction layer to maintain; only pays off if portability is a real requirement |

The key thing: **Vercel AI SDK and Bedrock are application-runtime tools** (production inference in deployed services). This PR is **editor-time tooling** (scaffolding the developer's loop). They're not really substitutes — they solve different problems. The honest comparison is "opencode-native" vs. "custom runtime-agnostic scaffolding."

### Pros of staying opencode-native (this PR's approach)

- Highest leverage per line: a 200-line markdown file becomes a working subagent, no glue code.
- Native dispatch (`@agent-X`) and tool-permission model are already battle-tested.
- Consistent with the rest of the repo — opencode is already the editor for this team.
- Meta-agents (`agent-maker` / `agent-modifier`) are only tractable because the target format is fixed and simple.
- For *editor-side* tasks, opencode-specific features (question tool, subagent mode, temperature override) are the value, not the lock-in.

### Cons / what we accept

- **Runtime lock-in.** If we ever want these agents to run inside a deployed app (Bedrock, a Lambda, an Elysia route), we re-author them. A `code-reviewer` agent here is not a `code-reviewer` agent in production.
- **No spec/runtime separation.** The "what the agent does" (prompt, tools, temp) is intermingled with "how opencode parses it." A future migration is N file rewrites, not a config swap.
- **Model tier names (`high|medium|low`) are an opencode abstraction.** They map to specific models inside opencode config; a different host wouldn't know what `medium` means.
- **`opencode.json` is now load-bearing.** ~784 lines of agent registration is a big merge-conflict surface and a single point of failure for the whole catalog.
- **Meta-agents amplify the coupling.** `agent-maker` doesn't generate a portable spec; it generates more opencode files. Every wizard run deepens the commitment.

### Why I'm not blocking

For *this* problem (agent dev/maintenance tooling for a team that already uses opencode), the lock-in is the feature, not the bug. Building a runtime-agnostic spec layer would slow this PR down 3-5x for portability we don't currently need. The Vercel AI SDK / Bedrock comparison only becomes real the day we want one of these agents to run inside a Prima delivery product surface — and at that point, we'd lift the *prompt* out of the markdown and re-host it, which is a manageable cost.

### 🟡 [important] Request: ADR for the agent scaffolding layer

Before this lands, I'd like an ADR that records this decision so the next person doesn't have to re-derive it. Proposed scope:

- **Title:** "Agent scaffolding layer: opencode-native vs. runtime-agnostic spec"
- **Status:** Accepted
- **Context:** This PR registers 117 agents in opencode-specific format. We considered Vercel AI SDK, AWS Bedrock Agents, and a custom runtime-agnostic spec layer.
- **Decision:** Adopt opencode-native scaffolding for editor-time developer tooling.
- **Consequences:** Runtime lock-in (acceptable for editor-side tooling), agents are not portable to product runtime as-is, meta-agents (`agent-maker`/`agent-modifier`) entrench the format.
- **When we'd revisit:** First time we need an agent's prompt to run inside a deployed product surface (Bedrock, Lambda, Elysia route). At that point, the prompt body is portable; the harness is not.
- **Boundary:** This ADR governs *editor-time* agents only. Production inference inside deployed apps is out of scope and would warrant its own ADR (likely Vercel AI SDK or Bedrock).

Per our team convention, ADRs live in `.global/taxonomy/design/adr/` and should be authored by the spec owner, not the implementer of this PR — so the ask is to file the ADR ticket, not to write it inside this PR.

### 🟢 [nit] Non-blocking suggestions

1. One paragraph in `docs/architecture.md` calling out: "These agents are editor-time tooling, scoped to opencode. Production inference belongs in app-runtime tools (Vercel AI SDK / Bedrock) and would be a separate effort."
2. Keep prompts in the markdown body free of opencode-specific verbs where possible (e.g., "ask the user" rather than "use the question tool") — that way the prompt content itself stays portable even if the harness isn't.

🟢 Approving on architectural grounds. The ADR ask above is the one thing I'd like tracked before/alongside merge.

---

Re-reading my comment above, I want to sharpen the point because I think I buried it.

My concern isn't that opencode is the wrong choice for editor tooling — for that, it's fine. The concern is that **this PR commits us harder to opencode as the substrate without us having decided whether "shared agents across runtimes" is an org-level goal.**

If shared/portable agents *is* a goal (one agent spec, multiple harnesses — opencode for editor-time, Vercel AI SDK or Bedrock for product-runtime), then this PR is heading the wrong way:

- 117 agents authored in opencode-specific format, not a portable spec.
- `opencode.json` (~784 lines) becomes the registration source of truth.
- Meta-agents (`agent-maker` / `agent-modifier`) generate *more* opencode-shaped files, so every wizard run deepens the foreclosure rather than producing a portable artifact.

If shared/portable agents *isn't* a goal — i.e. we're explicitly fine with editor-side and product-side agents being separately authored and maintained — then this PR is fine and the ADR is just bookkeeping.

I don't think that question has been answered, and I don't think this PR should be the place we silently answer it by accumulating opencode-shaped files.

**Reframing the ADR ask:** the ADR should be a *precondition* to this direction, not a follow-up that documents a decision already made. Specifically it should decide:

1. Are shared agents across runtimes (editor + product) a goal for the platform?
2. If yes — what's the portable spec, and does this PR get refactored against it before merge, or do we accept the migration cost later?
3. If no — record that explicitly so future contributors don't waste cycles on the portability question.

I'm walking back the 🟢 approve from my earlier comment and converting it to 🟡 — not blocking on code quality (the agents themselves look well-designed), but I'd like the strategic question answered before we 10x the opencode footprint.

To be clear: **this is meant as a discussion, not a hard block.** If the team has already had this conversation and I missed it, or if there's context that makes the portability question moot, I'm happy to be overruled and move the 🟡 back to 🟢. I'd rather raise it now and be wrong than stay quiet and have us realize the foreclosure cost six months from now.
