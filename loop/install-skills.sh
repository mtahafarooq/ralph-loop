#!/usr/bin/env bash
set -euo pipefail

LOOP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="${RALPH_PROJECT_ROOT:-$(dirname -- "$LOOP_DIR")}"
REGISTRY=".agents"
MODE="install"
DRY_RUN=0
SKILLS=(prd-generator prd-to-json)

usage() {
  printf '%s\n' \
    'Usage: loop/install-skills.sh [--registry .agents|.commandcode] [--dry-run] [--uninstall]' \
    '' \
    'Creates relative discovery symlinks without overwriting existing paths.'
}

while (($#)); do
  case "$1" in
    --registry)
      [[ $# -ge 2 ]] || { printf 'Missing value for --registry\n' >&2; exit 2; }
      REGISTRY="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --uninstall)
      MODE="uninstall"
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

case "$REGISTRY" in
  .agents|.commandcode) ;;
  *)
    printf 'Registry must be .agents or .commandcode.\n' >&2
    exit 2
    ;;
esac

DEST_DIR="$PROJECT_ROOT/$REGISTRY/skills"
RELATIVE_PREFIX="../../loop/skills"

if [[ "$MODE" == install ]]; then
  if ((DRY_RUN)); then
    printf 'Would create directory: %s\n' "$DEST_DIR"
  else
    mkdir -p "$DEST_DIR"
  fi
fi

for skill in "${SKILLS[@]}"; do
  source_path="$LOOP_DIR/skills/$skill"
  destination="$DEST_DIR/$skill"
  relative_target="$RELATIVE_PREFIX/$skill"

  [[ -d "$source_path" ]] || {
    printf 'Missing bundled skill: %s\n' "$source_path" >&2
    exit 1
  }

  if [[ "$MODE" == install ]]; then
    if [[ -L "$destination" ]]; then
      existing_target="$(readlink "$destination")"
      if [[ "$existing_target" == "$relative_target" ]]; then
        printf 'Already registered: %s\n' "$destination"
        continue
      fi
      printf 'Refusing to replace link: %s -> %s\n' "$destination" "$existing_target" >&2
      exit 1
    fi
    if [[ -e "$destination" ]]; then
      printf 'Refusing to overwrite existing path: %s\n' "$destination" >&2
      exit 1
    fi
    if ((DRY_RUN)); then
      printf 'Would link: %s -> %s\n' "$destination" "$relative_target"
    else
      ln -s "$relative_target" "$destination"
      printf 'Registered: %s -> %s\n' "$destination" "$relative_target"
    fi
  else
    if [[ ! -L "$destination" ]]; then
      if [[ -e "$destination" ]]; then
        printf 'Refusing to remove non-link path: %s\n' "$destination" >&2
        exit 1
      fi
      printf 'Not registered: %s\n' "$destination"
      continue
    fi
    existing_target="$(readlink "$destination")"
    if [[ "$existing_target" != "$relative_target" ]]; then
      printf 'Refusing to remove foreign link: %s -> %s\n' "$destination" "$existing_target" >&2
      exit 1
    fi
    if ((DRY_RUN)); then
      printf 'Would remove link: %s\n' "$destination"
    else
      rm "$destination"
      printf 'Removed: %s\n' "$destination"
    fi
  fi
done
