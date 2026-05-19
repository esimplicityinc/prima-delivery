# responses to harness agnosticism

First, I want to thank Fareez for raising a worthy question and articulating it well. The term Agent is dreadfully overloaded in our field so I'm parsing Fareez's distinction between two models of agent / skill use.

## editor-time vs. application-runtime

On first read, I thought Fareez was conflating models and harnesses. Re-reading his analysis, I
think the mistake was mine. His distinction is between *editor-time* harnesses (opencode running
in a developer's IDE session) and *application-runtime* harnesses (Vercel AI SDK or Bedrock
running inside a deployed service).

For completeness, here is how the editor-time side works: `@agent` and skill definitions are made available to a model by the harness. For `@agent` mentions the harness injects an `Agent` tool into the downstream. This is the same mechanism that the harness uses to tell the model that it is able and willing to provide a `bash` tool to the model. It is the model that decides to avail itself of that tool. For example, the model can pass back a request like

    task({ agent: "code-reviewer", prompt: "Review the auth changes" })

Similarly, skill definitions are aggregated by the harness and injected into the system prompt as a block like

```xml
<available_skills>
  <skill>
    <name>git-release</name>
    <description>Create consistent releases and changelogs</description>
...
```

and the model may then request skill injection by the harness like

    skill({ name: "git-release" })

when it decides it wants the full SKILL.md based on the description. The point is that agent and skill definitions are harness concepts which the model never sees, it only gets them predigested as tool definitions and a skill catalog.

None of this is portable to Vercel AI SDK or Bedrock, and Fareez is not claiming it should be. His table says explicitly that those tools are "not substitutes — they solve different problems."

## prompt reuse without harnesses

Fareez says this himself: "the prompt body is portable; the harness is not." I think we are in full agreement here and I want to be a little more explicit about that.

Absent the harness injection mechanisms above, how can a production Vercel AI make use of our opencode biased definitions? In the main, elements of `prima-delivery` need to be incorporated into production prompts. This is trivially solved by pushing the Markdown content from Agents and Skills into the Vercel prompt.

The mechanism that harnesses use is an interactive performance optimization that can't happen in a production context. So rolling the relevant texts into the prompt is a natural substitution for the Agent environment that doesn't exist in production use.

## OpenPackage portability

The various harnesses that our clients might use are a swiftly moving target. I'm provincial enough to believe that opencode, Claude, and Copilot cover many client use cases. OpenPackage claims to adapt Agent and Skills to those harnesses and more. If we want to be harness agnostic, then there is a promise that we can be.

I've not looked into OpenPackage well enough to know. I also accept that my harness lists is dreadfully incomplete, but [OpenPackage claims much wider support](https://openpackage.dev/docs/platforms).
