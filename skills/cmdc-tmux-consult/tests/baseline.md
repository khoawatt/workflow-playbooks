# Baseline observations

These scenarios were run without `cmdc-tmux-consult` before the skill or helper existed.

## Pane selection

The baseline inspected pane process state and scrollback, but hard-coded a project path and sent both the launch command and prompt with `tmux send-keys`. It had no reusable rule for ties between idle panes and no literal-paste protection for prompts containing shell syntax.

## Prompt delivery

The baseline correctly proposed a quoted heredoc and disposable tmux buffer. It did not combine that technique with Command Code readiness detection, repository validation, or completion evidence, so it was safe only as a manual fragment.

## Completion detection

The baseline proposed a sound running → possible-done → stable-done state machine and preserved the session on timeout. It would pause on Taste onboarding and require user input; launching with `--skip-onboarding` removes that avoidable blocking state.

## Guidance required

The skill must bind these pieces into one workflow: repository-agnostic pane validation, fixed safe launch arguments, literal prompt paste, ready → running → stable-ready monitoring, and mandatory Codex review of output and repository state.
