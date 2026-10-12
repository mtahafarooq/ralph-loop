#!/usr/bin/env bash
set -euo pipefail

# One fresh agent iteration. The project root is loop/'s parent.
LOOP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$(dirname -- "$LOOP_DIR")"

[[ -f "$LOOP_DIR/prd.json" ]] || {
  echo "Create loop/prd.json first (copy loop/prd.json.example)." >&2
  exit 1
}

cmd -p --yolo --verbose "$(cat "$LOOP_DIR/PROMPT.md")"
