#!/usr/bin/env bash
set -euo pipefail

LOOP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
RUNTIME_DIR="$LOOP_DIR/.runtime"
LOCK_DIR="$RUNTIME_DIR/lock"
MAX_ITERATIONS="${RALPH_MAX_ITERATIONS:-10}"

usage() {
  printf '%s\n' 'Usage: loop/ralph.sh [MAX_ITERATIONS] [ralph-once options...]'
}

if [[ ${1:-} =~ ^[0-9]+$ ]]; then
  MAX_ITERATIONS="$1"
  shift
elif [[ ${1:-} == '-h' || ${1:-} == '--help' ]]; then
  usage
  exit 0
fi

[[ "$MAX_ITERATIONS" =~ ^[1-9][0-9]*$ ]] || {
  printf 'MAX_ITERATIONS must be a positive integer.\n' >&2
  exit 2
}
"$LOOP_DIR/validate-prd.sh" "$LOOP_DIR/prd.json"

mkdir -p "$RUNTIME_DIR"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  printf 'Another Ralph loop appears to be running: %s\n' "$LOCK_DIR" >&2
  exit 1
fi
cleanup() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for ((iteration = 1; iteration <= MAX_ITERATIONS; iteration++)); do
  printf '\nRalph iteration %d/%d\n' "$iteration" "$MAX_ITERATIONS"
  before_state="$(cksum < "$LOOP_DIR/prd.json")"
  output_file="$RUNTIME_DIR/iteration-output-$$.log"

  set +e
  "$LOOP_DIR/ralph-once.sh" "$@" 2>&1 | tee "$output_file"
  run_status=${PIPESTATUS[0]}
  set -e

  if ((run_status != 0)); then
    printf 'Ralph iteration failed with exit code %d.\n' "$run_status" >&2
    exit "$run_status"
  fi
  if grep -Eq '<ralph>(BLOCKED|FAILED):' "$output_file"; then
    printf 'Ralph stopped after a blocked or failed iteration.\n' >&2
    exit 1
  fi

  all_complete="$(jq -r '(.tasks | all(.passes == true))' "$LOOP_DIR/prd.json")"
  if grep -Fq '<promise>COMPLETE</promise>' "$output_file"; then
    if [[ "$all_complete" == true ]]; then
      printf 'All Ralph tasks are complete.\n'
      exit 0
    fi
    printf 'Agent emitted completion while incomplete tasks remain.\n' >&2
    exit 1
  fi

  "$LOOP_DIR/validate-prd.sh" "$LOOP_DIR/prd.json"
  after_state="$(cksum < "$LOOP_DIR/prd.json")"
  if [[ "$before_state" == "$after_state" ]]; then
    printf 'Ralph stopped because prd.json did not change.\n' >&2
    exit 1
  fi
  if ! grep -Eq '<ralph>ITERATION_COMPLETE:TASK-[0-9]+</ralph>' "$output_file"; then
    printf 'Ralph stopped because the success marker was missing.\n' >&2
    exit 1
  fi
done

printf 'Ralph reached the maximum of %d iterations with work remaining.\n' "$MAX_ITERATIONS" >&2
exit 1
