#!/usr/bin/env bash
set -euo pipefail

PROGRAM=${0##*/}
PANE=
REPO_ROOT=
PROMPT=
MODE=plan
TIMEOUT=600
POLL=2
LOG_PATH=
SELECT_PANE=1

usage() {
  cat <<'USAGE'
Usage: cmdc-tmux-consult.sh [options] --prompt TEXT

Consult Command Code in an existing idle tmux pane.

Options:
  --pane TARGET       explicit tmux target (session:window.pane or pane id)
  --repo-root PATH    repository root (default: git root or current directory)
  --prompt TEXT       prompt to submit
  --mode MODE         plan (default) or standard
  --timeout SECONDS   timeout for each wait phase (default: 600)
  --poll SECONDS      polling interval (default: 2)
  --log PATH          evidence log path (default: temporary file)
  --no-select         do not focus the target pane
  -h, --help          show this help
USAGE
}

die() {
  local code=$1
  shift
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  exit "$code"
}

need_value() {
  [[ $# -ge 2 && -n ${2:-} ]] || die 1 "$1 requires a value"
}

while (($#)); do
  case $1 in
    --pane) need_value "$@"; PANE=$2; shift 2 ;;
    --repo-root) need_value "$@"; REPO_ROOT=$2; shift 2 ;;
    --prompt) need_value "$@"; PROMPT=$2; shift 2 ;;
    --mode) need_value "$@"; MODE=$2; shift 2 ;;
    --timeout) need_value "$@"; TIMEOUT=$2; shift 2 ;;
    --poll) need_value "$@"; POLL=$2; shift 2 ;;
    --log) need_value "$@"; LOG_PATH=$2; shift 2 ;;
    --no-select) SELECT_PANE=0; shift ;;
    --yolo|--dangerously-skip-permissions)
      die 1 "forbidden permission bypass: $1"
      ;;
    -h|--help) usage; exit 0 ;;
    *) die 1 "unknown argument: $1" ;;
  esac
done

[[ $MODE == plan || $MODE == standard ]] || die 1 "mode must be plan or standard"
[[ $TIMEOUT =~ ^[1-9][0-9]*$ ]] || die 1 "timeout must be a positive integer"
[[ $POLL =~ ^[0-9]+([.][0-9]+)?$ ]] || die 1 "poll must be a non-negative number"
[[ -n $PROMPT ]] || die 1 "--prompt is required"

command -v tmux >/dev/null 2>&1 || die 2 "tmux not found"
command -v cmdc >/dev/null 2>&1 || die 2 "cmdc not found"
cmdc status >/dev/null 2>&1 || die 2 "cmdc is not authenticated; run 'cmdc login'"

TMUX=(tmux)
if [[ -n ${CMDC_TMUX_SOCKET:-} ]]; then
  TMUX+=( -S "$CMDC_TMUX_SOCKET" )
fi

"${TMUX[@]}" list-panes -a >/dev/null 2>&1 || die 2 "tmux server is not running"

if [[ -z $REPO_ROOT ]]; then
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
fi
[[ -d $REPO_ROOT ]] || die 1 "repository root does not exist: $REPO_ROOT"
REPO_ROOT=$(cd "$REPO_ROOT" && pwd -P)

pane_field() {
  "${TMUX[@]}" display-message -p -t "$1" "$2" 2>/dev/null
}

pane_tail() {
  "${TMUX[@]}" capture-pane -p -t "$1" -S -120 2>/dev/null
}

is_shell() {
  case $1 in
    bash|zsh|fish|sh|dash|ksh) return 0 ;;
    *) return 1 ;;
  esac
}

is_idle_shell() {
  local target=$1 command tail last
  command=$(pane_field "$target" '#{pane_current_command}') || return 1
  is_shell "$command" || return 1
  tail=$(pane_tail "$target") || return 1
  last=$(printf '%s\n' "$tail" | sed '/^[[:space:]]*$/d' | tail -n 1)
  [[ $last =~ (\$|#|%|\>)[[:space:]]*$ ]]
}

if [[ -n $PANE ]]; then
  pane_field "$PANE" '#{pane_id}' >/dev/null || die 3 "pane not found: $PANE"
  is_idle_shell "$PANE" || die 3 "pane is not an idle shell: $PANE"
else
  candidates=()
  while IFS= read -r candidate; do
    [[ -n $candidate ]] || continue
    candidate_path=$(pane_field "$candidate" '#{pane_current_path}' 2>/dev/null || true)
    if [[ -d $candidate_path ]]; then
      candidate_path=$(cd "$candidate_path" && pwd -P)
    fi
    if [[ $candidate_path == "$REPO_ROOT" ]] && is_idle_shell "$candidate"; then
      candidates+=("$candidate")
    fi
  done < <("${TMUX[@]}" list-panes -a -F '#{pane_id}')
  ((${#candidates[@]} == 1)) || die 3 "expected one idle shell pane in repository, found ${#candidates[@]}; use --pane"
  PANE=${candidates[0]}
fi

PANE_PATH=$(pane_field "$PANE" '#{pane_current_path}')
[[ -d $PANE_PATH ]] || die 3 "pane directory does not exist: $PANE_PATH"
PANE_PATH=$(cd "$PANE_PATH" && pwd -P)
[[ $PANE_PATH == "$REPO_ROOT" ]] || \
  die 3 "pane directory '$PANE_PATH' does not match repository root '$REPO_ROOT'"

if [[ -z $LOG_PATH ]]; then
  LOG_PATH=$(mktemp "${TMPDIR:-/tmp}/cmdc-tmux-consult.XXXXXX.log")
else
  mkdir -p "$(dirname "$LOG_PATH")"
  : >"$LOG_PATH"
fi
chmod 600 "$LOG_PATH"

PROMPT_BYTES=$(printf '%s' "$PROMPT" | wc -c | tr -d ' ')
if command -v sha256sum >/dev/null 2>&1; then
  PROMPT_SHA=$(printf '%s' "$PROMPT" | sha256sum | awk '{print $1}')
else
  PROMPT_SHA=$(printf '%s' "$PROMPT" | shasum -a 256 | awk '{print $1}')
fi
BASELINE_STATUS=$(git -C "$REPO_ROOT" status --short 2>/dev/null || true)

launch=(cmdc)
[[ $MODE == plan ]] && launch+=(--plan)
launch+=(--trust --skip-onboarding)
printf -v LAUNCH_DISPLAY '%q ' "${launch[@]}"
LAUNCH_DISPLAY=${LAUNCH_DISPLAY% }

"${TMUX[@]}" send-keys -t "$PANE" -l -- "exec $LAUNCH_DISPLAY"
"${TMUX[@]}" send-keys -t "$PANE" C-m

marker='❯ Ask your question...'
deadline=$((SECONDS + TIMEOUT))
ready_tail=
while ((SECONDS < deadline)); do
  ready_tail=$(pane_tail "$PANE" || true)
  if [[ $ready_tail == *"$marker"* ]]; then
    break
  fi
  sleep "$POLL"
done
[[ $ready_tail == *"$marker"* ]] || die 5 "timed out waiting for Command Code readiness in pane $PANE"

initial_markers=$(grep -Foc "$marker" <<<"$ready_tail" || true)
buffer="cmdc-consult-$$-$RANDOM"
printf '%s' "$PROMPT" | "${TMUX[@]}" load-buffer -b "$buffer" -
if ! "${TMUX[@]}" paste-buffer -p -b "$buffer" -t "$PANE" -d; then
  "${TMUX[@]}" delete-buffer -b "$buffer" 2>/dev/null || true
  die 4 "failed to paste prompt into pane $PANE"
fi
"${TMUX[@]}" send-keys -t "$PANE" C-m

deadline=$((SECONDS + TIMEOUT))
stable=0
last_hash=
final_tail=
while ((SECONDS < deadline)); do
  final_tail=$(pane_tail "$PANE" || true)
  marker_count=$(grep -Foc "$marker" <<<"$final_tail" || true)
  if ((marker_count > initial_markers)); then
    normalized=$(printf '%s' "$final_tail" | sed -E 's/[[:space:]]+$//')
    if command -v sha256sum >/dev/null 2>&1; then
      current_hash=$(printf '%s' "$normalized" | sha256sum | awk '{print $1}')
    else
      current_hash=$(printf '%s' "$normalized" | shasum -a 256 | awk '{print $1}')
    fi
    if [[ $current_hash == "$last_hash" ]]; then
      stable=$((stable + 1))
    else
      stable=0
      last_hash=$current_hash
    fi
    ((stable >= 1)) && break
  fi
  sleep "$POLL"
done
((stable >= 1)) || die 5 "timed out waiting for Command Code completion in pane $PANE; session was left running"

FINAL_STATUS=$(git -C "$REPO_ROOT" status --short 2>/dev/null || true)
redacted_tail=${final_tail//"$PROMPT"/[REDACTED_PROMPT]}
{
  printf 'timestamp=%s\n' "$(date -Is)"
  printf 'repository_root=%s\n' "$REPO_ROOT"
  printf 'pane=%s\n' "$PANE"
  printf 'launch_argv=%s\n' "$LAUNCH_DISPLAY"
  printf 'prompt_bytes=%s\n' "$PROMPT_BYTES"
  printf 'prompt_sha256=%s\n' "$PROMPT_SHA"
  printf 'completion_state=DONE_OPEN\n'
  printf 'baseline_git_status<<STATUS\n%s\nSTATUS\n' "$BASELINE_STATUS"
  printf 'final_git_status<<STATUS\n%s\nSTATUS\n' "$FINAL_STATUS"
  printf 'pane_tail<<OUTPUT\n%s\nOUTPUT\n' "$redacted_tail"
} >"$LOG_PATH"

if ((SELECT_PANE)); then
  "${TMUX[@]}" select-pane -t "$PANE" 2>/dev/null || true
fi

printf 'pane=%s\nrepository_root=%s\nevidence_log=%s\nstate=DONE_OPEN\n' \
  "$PANE" "$REPO_ROOT" "$LOG_PATH"
