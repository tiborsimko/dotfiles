---
name: relay-prepare
description: Prepare a human-in-the-loop relay packet — render the current conversation as a handoff for a collaborating AI agent and save it to a file. Does NOT touch the clipboard; run /relay-copy when you are ready to paste. Invoke only when the user explicitly runs /relay-prepare.
argument-hint: [target-agent]
disable-model-invocation: true
allowed-tools: Bash, Write
---

<!-- Keep behavior in sync with the Codex relay-prepare skill counterpart at codex/.agents/skills/relay-prepare/SKILL.md -->

Render a handoff packet from the CURRENT conversation and SAVE it to a file. Do
NOT copy to the clipboard — that is `/relay-copy`'s job, run when the human is
actually ready to paste (so it never clobbers their clipboard while they work
elsewhere). Do not edit any project files; the only file you write is the packet.

## 1. Target

The destination is "a collaborating AI agent" by default. If the user named a
specific target when invoking (e.g. `/relay-prepare codex`), use that name instead.

## 2. Render the packet

Build this exact Markdown structure from the CURRENT conversation. Fill each
section faithfully from real context; do not invent content.

```markdown
# Relay: from claude to <target>

## Originating request

<The task context the next agent needs — NOT the relay command itself, which is
only the trigger. Summarize what the user is actually trying to do and the
relevant recent exchange that led to the output below: their real goal, decisions
already made, and constraints to respect. Quote the user verbatim where a specific
ask matters.>

## My latest output

<Your most recent substantive answer — the thing being handed off. Carry it
faithfully: preserve recommendations, caveats, concrete examples, and specific
wording when it matters. Quote yourself verbatim where exact phrasing carries
weight, rather than re-summarizing away the substance.>

## Constraints & repo context

<Anything the next agent needs in order not to break things: files in play,
decisions already made, what is explicitly out of scope.>

## Open questions for you

<What you want the next agent to review, decide, or push back on.>

## Human user comments

<!-- The human user writes here before sending. Leave this section empty. -->
```

Keep it concise — this turn's output and the immediate question, not the whole
back-and-forth (the other agent keeps its own session). "Concise" means drop prior
history, not compress the substance out of the latest answer. Never include API
keys, tokens, or other secrets.

## 3. Compute the target path (one Bash call)

Run exactly this and read the absolute path it prints:

```sh
RELAY_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ai-relay"
mkdir -p "$RELAY_DIR"
date +"$RELAY_DIR/%Y%m%d-%H%M%S-claude.md"
```

Shell variables do not persist into later tool calls, so use the LITERAL absolute
path printed here for the write below.

## 4. Write the packet

Use the `Write` tool to write the rendered packet to that exact printed path. Do
NOT write it with `echo`/heredoc — the structured write avoids quoting breakage on
multi-line / shell-hostile content.

## 5. Report — do NOT copy

Do NOT run `pbcopy`. Reply with exactly this marker line (so `/relay-copy` can find
the path later) followed by a one-line reminder, then stop:

```
Prepared relay packet: <absolute path>
Run /relay-copy in this session when you're ready to paste.
```
