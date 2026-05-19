# responses to harness agnosticism

First, I want to thank Fareez for raising a worthy question and articulating it well. I agree with much of his analysis but either differ on some of his points or (perhaps more likely) don't fully understand him.

## models vs. harnesses

I'm puzzled by the conflation of models and harnesses. It seems to me that the agents and skills living in `prima-delivery` are used by harnesses and are independent of the models used by the harness.

Put another way `@agent` and skill definitions are made available to a model by the harness. For `@agent` mentions the harness injects an `Agent` tool into the downstream. This is the same mechanism that the harness uses to tell the model that it is able and willing to provide a `bash` tool to the model. It is the model that decides to avail itself of that tool. For example, the model can pass back a request like

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

I admit that I don't understand the distinction Fareez makes between application-runtime tools and editor-time tooling. If, as I'm claiming, agents and skills are harness concepts, I'm unclear why Vercel and Bedrock are present in his analysis. I'm not sure agents and skill are meaningful in application-runtime contexts.


## openpackage rewriting capabilities
