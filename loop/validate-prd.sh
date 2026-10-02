#!/usr/bin/env bash
set -euo pipefail

LOOP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PRD_FILE="${1:-$LOOP_DIR/prd.json}"

command -v jq >/dev/null 2>&1 || {
  printf 'jq is required to validate the Ralph backlog.\n' >&2
  exit 1
}
[[ -f "$PRD_FILE" ]] || {
  printf 'PRD file not found: %s\n' "$PRD_FILE" >&2
  exit 1
}

jq -e '
  def task_ids: [.tasks[].id];
  def branch_names: [.tasks[].branchName];
  def reaches($tasks; $from; $target; $seen):
    if ($seen | index($from)) != null then false
    elif $from == $target then true
    else
      (($tasks[] | select(.id == $from) | .dependsOn) // []) as $dependencies
      | any($dependencies[]?; reaches($tasks; .; $target; $seen + [$from]))
    end;

  .schemaVersion == 1 and
  (.project | type == "string") and
  (.description | type == "string") and
  (.tasks | type == "array") and
  all(.tasks[];
    (.id | type == "string" and test("^TASK-[0-9]{3,}$")) and
    (.title | type == "string" and length > 0) and
    (.description | type == "string" and length > 0) and
    (.branchName | type == "string" and length > 0) and
    (.priority | type == "number" and floor == . and . >= 1) and
    (.dependsOn | type == "array" and length == (unique | length)) and
    (.acceptanceCriteria | type == "array" and length > 0 and all(.[]; type == "string" and length > 0)) and
    (.passes | type == "boolean") and
    (.notes | type == "string")
  ) and
  ((task_ids | length) == (task_ids | unique | length)) and
  ((branch_names | length) == (branch_names | unique | length)) and
  (task_ids as $ids | all(.tasks[]; .id as $self | all(.dependsOn[]?; . as $dependency | $dependency != $self and ($ids | index($dependency) != null)))) and
  (.tasks as $tasks | all(.tasks[]; .id as $id | all(.dependsOn[]?; (reaches($tasks; .; $id; []) | not))))
' "$PRD_FILE" >/dev/null || {
  printf 'Invalid Ralph backlog structure or dependency graph: %s\n' "$PRD_FILE" >&2
  exit 1
}

while IFS= read -r branch_name; do
  git check-ref-format --branch "$branch_name" >/dev/null 2>&1 || {
    printf 'Invalid Git branch name in Ralph backlog: %s\n' "$branch_name" >&2
    exit 1
  }
done < <(jq -r '.tasks[].branchName' "$PRD_FILE")
