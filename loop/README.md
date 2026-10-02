# Ralph loop package

Copy this directory to `<project-root>/loop`. It is intentionally project-local: the scripts run against the parent project, while prompts, state, skills, and runtime logs remain together.

## How the loop works

Open [The Fresh-Context Relay](docs/ralph-flowchart.html) for an offline interactive walkthrough of one supervised run, durable handoff state, every outer-loop stop condition, and a small scenario simulator. It runs directly in the browser and does not inspect or change the project.

## Requirements

- Bash
- Git for task branches and atomic commits
- `jq` for backlog checks
- A coding-agent CLI that accepts the prompt as its final argument

The default invocation is:

```sh
cmd -p --yolo '<prompt>'
```

Unattended agent execution can modify code and create commits. Review the prompt and permissions, begin on a disposable feature branch or worktree, and keep the first runs supervised. This package never modifies a host `.commandcode/settings.json`; merge required permissions yourself.

## Recommended workflow

### 1. Register the bundled skills

From the project root:

```sh
./loop/install-skills.sh
```

This creates relative links under `.agents/skills/`. It never overwrites an existing path. For Command Code-specific discovery instead:

```sh
./loop/install-skills.sh --registry .commandcode
```

Do not register both unless your agent explicitly deduplicates identical skills. Preview or remove package-owned links with:

```sh
./loop/install-skills.sh --dry-run
./loop/install-skills.sh --uninstall
```

On systems where symlinks are unavailable, manually copy the two skill directories and manage updates yourself; the installer will not silently create drifting copies.

### 2. Create and approve a Markdown PRD

Invoke `prd-generator` with the feature idea. It inspects the project, asks focused requirements questions, and writes `loop/prd.md` by default. Review and approve that document before decomposition.

### 3. Generate the executable backlog

Invoke `prd-to-json` to convert the approved PRD into `loop/prd.json`. Every task has its own branch, dependencies, acceptance criteria, priority, completion flag, and notes.

```json
{
  "$schema": "./prd.schema.json",
  "schemaVersion": 1,
  "project": "Example",
  "description": "Example feature",
  "tasks": [
    {
      "id": "TASK-001",
      "title": "Add login form",
      "description": "Implement login inputs and validation.",
      "branchName": "ralph/task-001-login-form",
      "priority": 1,
      "dependsOn": [],
      "acceptanceCriteria": [
        "Email and password fields are present.",
        "Invalid email formats are rejected.",
        "Relevant project checks pass."
      ],
      "passes": false,
      "notes": ""
    }
  ]
}
```

A task is ready when it has not passed and all dependencies have passed. The lowest numeric priority runs first; document order breaks ties. See [`prd.json.example`](prd.json.example) for a complete multi-task backlog with parallel work, dependency chains, per-task branches, and recorded completion evidence.

Copy the example only when you want a starting reference; `prd-to-json` writes the active backlog to `loop/prd.json`.

### 4. Learn with one run

Run one supervised iteration:

```sh
./loop/ralph-once.sh
```

The script executes from the host project root regardless of your current directory, captures output under `loop/.runtime/logs/`, and returns the agent's exit status. It performs no internal repetition. Follow the [single-run chapter](docs/ralph-flowchart.html#single-run) to inspect each boundary and decision.

Commits are enabled by default. Disable them while learning:

```sh
RALPH_AUTO_COMMIT=0 ./loop/ralph-once.sh
```

### 5. Enable the bounded loop

After the one-run behavior is reliable:

```sh
./loop/ralph.sh 10
```

Every iteration creates a fresh agent process. The loop stops on verified completion, failure, blocked work, unchanged state, a malformed protocol result, concurrent execution, or the iteration limit. It does not retry failures automatically. The [bounded-loop chapter](docs/ralph-flowchart.html#bounded-loop) shows these checks in execution order.

## Agent configuration

Choose another executable and replace the default `-p --yolo` arguments with repeated options:

```sh
./loop/ralph-once.sh \
  --agent my-agent \
  --agent-arg run \
  --agent-arg --non-interactive
```

The prompt is always passed as the final separately quoted argument; do not use an adapter that requires shell evaluation. The same options can follow the iteration count for the outer loop:

```sh
./loop/ralph.sh 5 --agent my-agent --agent-arg run
```

Use `RALPH_PROJECT_ROOT=/path/to/project` when `loop/` is not directly under the intended project root.

## Persistent and runtime state

- `PROMPT.md`: the single-iteration behavioral and output protocol.
- `prd.json`: the versioned task queue and completion state.
- `prd.schema.json`: the canonical task contract.
- `validate-prd.sh`: structural, dependency-graph, and Git branch validation.
- `progress.txt`: append-only handoff notes between fresh contexts.
- `.runtime/`: ignored logs and lock state; safe to inspect after failures.
- Git history: one verified task per atomic commit by default.

A progress entry should record timestamp, task ID/title/branch, summary, important files, validation commands and outcomes, commit hash when available, and remaining concerns.

## Recovery

If an iteration stops:

1. Read the terminal output and latest file under `loop/.runtime/logs/`.
2. Inspect `git status`, the selected task's notes, and the latest progress entry.
3. Resolve unsafe working-tree state, validation failures, or blocked dependencies manually.
4. Keep `passes: false` until every acceptance criterion succeeds.
5. Run `ralph-once.sh` again before resuming the outer loop.

Never bypass failed checks, reset unrelated changes, or mark a task passed solely to advance the loop.
