#!/usr/bin/env bash
set -euo pipefail

LOOP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="${RALPH_PROJECT_ROOT:-$(dirname -- "$LOOP_DIR")}"
AGENT_BIN="${RALPH_AGENT_BIN:-cmd}"
AUTO_COMMIT="${RALPH_AUTO_COMMIT:-1}"
RUNTIME_DIR="$LOOP_DIR/.runtime"
LOG_DIR="$RUNTIME_DIR/logs"
AGENT_ARGS=()

usage() {
  printf '%s\n' \
    'Usage: loop/ralph-once.sh [--agent PATH] [--agent-arg ARG] [--no-commit]' \
    '' \
    'Defaults to: cmd -p --yolo PROMPT' \
    'Use repeated --agent-arg options to replace the default agent arguments.'
}

while (($#)); do
  case "$1" in
    --agent)
      [[ $# -ge 2 ]] || { printf 'Missing value for --agent\n' >&2; exit 2; }
      AGENT_BIN="$2"
      shift 2
      ;;
    --agent-arg)
      [[ $# -ge 2 ]] || { printf 'Missing value for --agent-arg\n' >&2; exit 2; }
      AGENT_ARGS+=("$2")
      shift 2
      ;;
    --no-commit)
      AUTO_COMMIT=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ((${#AGENT_ARGS[@]} == 0)); then
  AGENT_ARGS=(-p --yolo)
fi

for required_file in PROMPT.md prd.json progress.txt; do
  [[ -f "$LOOP_DIR/$required_file" ]] || {
    printf 'Missing required file: %s\n' "$LOOP_DIR/$required_file" >&2
    exit 1
  }
done

"$LOOP_DIR/validate-prd.sh" "$LOOP_DIR/prd.json"

[[ -d "$PROJECT_ROOT" ]] || {
  printf 'Project root does not exist: %s\n' "$PROJECT_ROOT" >&2
  exit 1
}
command -v "$AGENT_BIN" >/dev/null 2>&1 || {
  printf 'Agent executable not found: %s\n' "$AGENT_BIN" >&2
  exit 1
}

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date -u +'%Y%m%dT%H%M%SZ')-$$.log"
PROMPT="$(cat "$LOOP_DIR/PROMPT.md")

Runtime context:
- Project root: $PROJECT_ROOT
- Loop directory: $LOOP_DIR
- Auto-commit enabled: $AUTO_COMMIT
- State files: @loop/prd.json @loop/progress.txt
"

cd "$PROJECT_ROOT"
printf 'Ralph log: %s\n' "$LOG_FILE"
set +e
"$AGENT_BIN" "${AGENT_ARGS[@]}" "$PROMPT" 2>&1 | tee "$LOG_FILE"
agent_status=${PIPESTATUS[0]}
set -e
exit "$agent_status"
