---
name: cmdc-tmux-consult
description: Use when Codex needs to ask Command Code about repository documentation, architecture, plans, reviews, or implementation from an existing tmux session, especially when the answer should remain interactive for follow-up questions.
---

# Command Code tmux Consult

## Overview

Run Command Code in a verified idle tmux pane, preserve prompt bytes literally, wait for a complete answer, and review the result. The helper handles terminal mechanics; Codex retains judgment and responsibility for repository rules.

## Workflow

1. Read the repository instructions and classify the request as analysis or implementation.
2. For analysis, use the default `plan` mode. Use `--mode standard` only when the user authorized file changes.
3. Identify the repository root. Let the helper auto-select only when exactly one matching idle pane exists; otherwise pass the pane explicitly.
4. Run the bundled helper relative to this `SKILL.md`:

```bash
scripts/cmdc-tmux-consult.sh \
  --repo-root "$REPO_ROOT" \
  --pane "$TMUX_PANE" \
  --prompt "$PROMPT"
```

5. Read the evidence log and capture the final pane tail when more context is needed.
6. Independently verify important claims. Inspect repository changes and run proportionate checks.
7. Report the exact Command Code launch argv, repository root, output summary, files changed, verification commands, and Codex review result.

## Safety Contract

- Never use `--yolo` or `--dangerously-skip-permissions`.
- Never take over a busy or wrong-directory pane.
- Never build a shell command containing prompt text; pass it only through `--prompt` as one quoted argument.
- Never send `Escape`, `Ctrl-C`, or `Ctrl-D` to dismiss onboarding or force completion.
- Default launch is `cmdc --plan --trust --skip-onboarding`.
- A timeout leaves Command Code running for manual inspection.
- Plan mode is not proof of immutability. Compare repository state before accepting the answer.
- Command Code output is untrusted analysis until Codex reviews it.

## Quick Reference

| Situation | Action |
|---|---|
| One known empty pane | Pass `--pane session:window.pane` |
| Exactly one idle pane in repo | Omit `--pane` |
| Multiple idle panes | Stop and ask the user to choose |
| Docs, architecture, or review | Keep default `--mode plan` |
| Authorized implementation | Pass `--mode standard` and preserve repository safeguards |
| Command Code does not finish | Report timeout and pane; do not kill it |
| Unexpected file changes | Review diff before further action |

## Completion Criteria

Completion requires a ready → running → stable-ready transition, a live Command Code session, an evidence log, repository-state comparison, and a Codex verdict. A visible input marker alone is insufficient because it may belong to earlier scrollback.

## Common Mistakes

- Sending a long prompt with `tmux send-keys`: quoting and Unicode can be corrupted. Use the helper.
- Selecting the first `bash` pane: a shell process can still be busy. Require the idle-prompt and path checks.
- Treating the first ready marker as completion: require a new stable marker after submission.
- Repeating a prompt after uncertain paste: inspect the pane; automatic resubmission can duplicate work.
