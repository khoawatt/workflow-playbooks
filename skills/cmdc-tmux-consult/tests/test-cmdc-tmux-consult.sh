#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
SCRIPT="$ROOT/scripts/cmdc-tmux-consult.sh"
TMP=$(mktemp -d)
PASS=0

cleanup() {
  local socket
  for socket in "$TMP"/socket-*; do
    [[ -e "$socket" ]] || continue
    tmux -S "$socket" kill-server 2>/dev/null || true
  done
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  PASS=$((PASS + 1))
  printf 'ok %d - %s\n' "$PASS" "$1"
}

assert_contains() {
  [[ $1 == *"$2"* ]] || fail "expected [$1] to contain [$2]"
}

new_fixture() {
  local name=$1
  FIXTURE="$TMP/$name"
  SOCKET="$TMP/socket-$name"
  REPO="$FIXTURE/repo"
  BIN="$FIXTURE/bin"
  LOG="$FIXTURE/evidence.log"
  mkdir -p "$REPO" "$BIN"
  git -C "$REPO" init -q
  cat >"$BIN/cmdc" <<'FAKE_CMDC'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == status ]]; then
  printf 'authenticated\n'
  exit 0
fi
printf 'Command Code test double\n❯ Ask your question...\n'
IFS= read -r prompt
printf 'RESPONSE:%s\n' "$prompt"
printf '❯ Ask your question...\n'
sleep 30
FAKE_CMDC
  chmod +x "$BIN/cmdc"
  tmux -S "$SOCKET" new-session -d -s consult -c "$REPO" \
    "env PS1='TEST$ ' PATH='$BIN:$PATH' bash --noprofile --norc"
  sleep 0.2
  PANE=$(tmux -S "$SOCKET" list-panes -t consult -F '#{pane_id}')
}

run_helper() {
  CMDC_TMUX_SOCKET="$SOCKET" PATH="$BIN:$PATH" "$SCRIPT" "$@"
}

[[ -x "$SCRIPT" ]] || fail "helper does not exist: $SCRIPT"

help_output=$($SCRIPT --help)
assert_contains "$help_output" 'cmdc-tmux-consult.sh'
pass 'prints help'

set +e
forbidden_output=$($SCRIPT --yolo 2>&1)
forbidden_status=$?
set -e
[[ $forbidden_status -eq 1 ]] || fail "--yolo exit was $forbidden_status"
assert_contains "$forbidden_output" 'forbidden'
pass 'rejects dangerous permission bypass'

new_fixture wrong-directory
mkdir -p "$FIXTURE/other"
set +e
wrong_output=$(run_helper --pane "$PANE" --repo-root "$FIXTURE/other" --prompt docs 2>&1)
wrong_status=$?
set -e
[[ $wrong_status -eq 3 ]] || fail "wrong-directory exit was $wrong_status"
assert_contains "$wrong_output" 'does not match repository root'
pass 'rejects pane in another directory'

new_fixture literal-prompt
prompt='Explain "docs" and keep $(touch /tmp/should-not-exist) literal — ไทย'
run_output=$(run_helper --pane "$PANE" --repo-root "$REPO" --prompt "$prompt" \
  --timeout 5 --poll 0.1 --log "$LOG" --no-select)
assert_contains "$run_output" "pane=$PANE"
tail_output=$(tmux -S "$SOCKET" capture-pane -p -t "$PANE" -S -30)
assert_contains "$tail_output" '$(touch /tmp/should-not-exist)'
[[ ! -e /tmp/should-not-exist ]] || fail 'prompt content executed in the shell'
assert_contains "$(<"$LOG")" 'prompt_sha256='
if grep -Fq "$prompt" "$LOG"; then
  fail 'evidence log leaked the prompt'
fi
pass 'pastes prompts literally and redacts evidence'

new_fixture timeout
cat >"$BIN/cmdc" <<'FAKE_TIMEOUT'
#!/usr/bin/env bash
if [[ ${1:-} == status ]]; then exit 0; fi
printf '❯ Ask your question...\n'
IFS= read -r prompt
printf 'still working\n'
sleep 30
FAKE_TIMEOUT
chmod +x "$BIN/cmdc"
set +e
timeout_output=$(run_helper --pane "$PANE" --repo-root "$REPO" --prompt docs \
  --timeout 1 --poll 0.1 --no-select 2>&1)
timeout_status=$?
set -e
[[ $timeout_status -eq 5 ]] || fail "timeout exit was $timeout_status"
assert_contains "$timeout_output" 'timed out'
tmux -S "$SOCKET" display-message -p -t "$PANE" '#{pane_dead}' | grep -qx 0 || \
  fail 'timeout killed the pane'
pass 'times out without killing the pane'

printf '1..%d\n' "$PASS"
