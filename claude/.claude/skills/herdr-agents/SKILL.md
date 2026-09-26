---
name: herdr-agents
description: Orchestrate parallel Claude subagents as visible herdr panes/worktrees instead of the invisible built-in Task tool. Spawn, monitor, communicate, and merge.
allowed-tools: Bash, Write, Read
disable-model-invocation: true
---

# Herdr Panel Agents

You are a coordinator. Unlike the built-in Task tool (subagents run in-process,
invisible to any terminal), this spawns real separate `claude` processes, each
in its own git worktree and its own herdr pane — visible in the herdr sidebar
with live status. Use this when the user wants to watch or steer parallel
work, not just get a final report back.

You do NOT implement tasks yourself. You spawn agents, monitor them, send
instructions, and trigger merges.

**Requires running under herdr**: check `$HERDR_ENV` and `$HERDR_WORKSPACE_ID`
are set before using this skill. If not, use `/coordinator` (workmux/tmux)
instead.

## Core Concepts

- **pane_id** (e.g. `w2H:p1`): the handle for every agent command (`prompt`,
  `get`, `wait`, `read`). Capture it from `worktree create --json` — never
  guess it.
- **workspace_id** (e.g. `w2H`): the worktree's herdr workspace, used only for
  cleanup (`worktree remove --workspace`).
- Each spawned worktree opens as its own workspace, visible in the herdr
  sidebar immediately (no hook wiring needed — Claude integration is already
  installed).
- **Statuses**: `idle`, `working`, `blocked`, `done`, `unknown` — herdr's own
  agent-state detection.

## Spawn Agents

For each task: create an isolated worktree, start Claude in its pane, submit
the prompt — without `--wait` (spawn all agents first, monitor after).

```bash
# 1. Create isolated git worktree + herdr workspace (run from the repo root)
result=$(herdr worktree create --branch auth-module --base main --label "auth module" --json)
pane_id=$(echo "$result" | jq -r '.result.root_pane.pane_id')
workspace_id=$(echo "$result" | jq -r '.result.workspace.workspace_id')

# 2. Start Claude in that pane (it's already at an interactive shell prompt)
herdr agent start auth-module --kind claude --pane "$pane_id"

# 3. Write a self-contained prompt file, then submit it (no --wait here)
tmpfile=$(mktemp).md
cat > "$tmpfile" << 'EOF'
Implement auth module...
EOF
herdr agent prompt "$pane_id" "$(cat "$tmpfile")"
```

Repeat for every task, THEN move to Monitor. Prompts must be self-contained —
the spawned agent cannot see this conversation. Use relative paths (each
worktree has its own root).

## Monitor

```bash
herdr agent list                                          # every agent, JSON
herdr agent get "$pane_id"                                # single snapshot -> agent_status
herdr agent wait "$pane_id" --until idle --until done --timeout 3600000   # ms; blocks
herdr agent read "$pane_id" --lines 100                   # last N lines, ANSI-stripped
```

`agent wait` takes exactly ONE target. To wait on several agents concurrently,
background the calls:

```bash
herdr agent wait "$pane_a" --timeout 3600000 &
herdr agent wait "$pane_b" --timeout 3600000 &
wait
```

Always pass `--timeout`. A timeout means "still running", not failure.

## Send Follow-up Instructions

```bash
herdr agent prompt "$pane_id" "fix the failing tests" --wait --until idle --timeout 1800000
```

`--wait` blocks until the agent settles into idle/done/blocked — use it for
follow-ups where you need the result before proceeding (e.g. right before a
merge instruction).

## Merge & Cleanup

Tell the agent to merge itself — it has full git access in its own worktree:

```bash
herdr agent prompt "$pane_id" "commit your changes, rebase onto main, then merge into main and delete this branch" --wait --until idle --timeout 300000
```

Read its output before trusting the merge happened, then tear down:

```bash
herdr pane close "$pane_id"
herdr worktree remove --workspace "$workspace_id" --force
```

## Rules

1. Write ALL prompt files before spawning any agent. Prompts must be
   self-contained (relative paths only).
2. Spawn all agents first without `--wait`, THEN monitor — blocking during
   spawn serializes what should be parallel.
3. `pane_id` is the handle for every command — capture it from
   `worktree create --json`, never derive or guess it.
4. Read output (`agent read --lines 100`) before merging. Don't blindly merge.
5. Merge one agent at a time; wait for each merge prompt to settle before
   starting the next, to avoid branch conflicts.
6. Clean up (`pane close` + `worktree remove --force`) once merged, unless the
   user wants to keep inspecting the worktree.
7. You are a coordinator, not an implementer — never edit source files
   yourself while agents are running.

## When to Use vs. Alternatives

- **Built-in Task tool** (Agent tool): fastest, in-process, invisible — good
  for research or one-shot delegated work you don't need to watch live.
- **`/coordinator` (workmux/tmux)**: use when the session runs inside tmux
  rather than herdr.
- **This skill**: use under herdr when the user wants to see and steer each
  subagent live as its own panel in the sidebar instead of an invisible
  background task.
