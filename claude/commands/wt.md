---
description: Run a task in a fresh herdr worktree; when it's merged, tear the worktree down
argument-hint: <task> | done [branch] | list
allowed-tools: Bash(herdr:*), Bash(git:*), Bash(gh:*)
---

Arguments: `$ARGUMENTS`

Requires `HERDR_ENV=1`. If it isn't set, say this only works inside herdr and stop.

**Always create and remove worktrees through `herdr worktree create/remove`.** `git worktree add/remove` emits no `worktree.created`/`worktree.removed` events, so the `freethinkel.worktree-hooks` plugin never runs (no `.env` symlink, no `node_modules`, no `settings.local.json`, no submodules). Hook config: `~/.config/herdr/plugins/config/freethinkel.worktree-hooks/config.yml`.

## Mode is picked from the argument

- empty → **list**
- `done [branch]` → **finish**
- anything else → **start**, the argument is the task description

## start

1. `REPO=$(git rev-parse --show-toplevel)`; bail if not a repo. `BASE=$(git branch --show-current)`.
2. Derive a branch name from the task: kebab-case, `[a-z0-9_-]`, ≤32 chars, starts with a letter (herdr validates this).
3. `WS=$(herdr pane current | jq -r .result.pane.workspace_id)` — if the current workspace is this repo, pass `--workspace $WS`; otherwise `--cwd $REPO` (that variant also opens an extra workspace for the main checkout).
   ```bash
   herdr worktree create --workspace "$WS" --branch "$BRANCH" --base "$BASE" --label "$LABEL" --no-focus
   ```
   Take `result.root_pane.pane_id` and `result.worktree.path` from the JSON.
4. Start the agent in that pane and hand it the task:
   ```bash
   herdr agent start "$BRANCH" --kind claude --pane "$PANE" --timeout 60000
   herdr agent prompt "$BRANCH" "$TASK"
   ```
   For a multi-line task pass `"$(cat file)"`.
   Append to the prompt: "herdr hooks are copying/installing dependencies into this worktree in the background — if a build or test fails on missing deps, wait and retry."
5. Report one line: branch, worktree path, pane id, and that `/wt done <branch>` closes it out.

## finish

No branch given — show the list (see list) and ask which one.

1. Locate it: `herdr worktree list --cwd "$REPO"` → the entry whose `branch` matches; keep `path` and `open_workspace_id`.
2. Uncommitted changes (`git -C "$WT" status --porcelain`) — stop and show them. Delete nothing.
3. Is it merged:
   - `git -C "$REPO" branch --merged "$BASE" | grep -qx "  $BRANCH"`, or
   - `gh pr view "$BRANCH" --json state -q .state` = `MERGED` (a squash merge is invisible to `--merged`).
   If not merged, say so and ask whether to merge into `$BASE` locally. Without confirmation, don't merge and don't remove.
4. Remove the worktree (this fires the `removed` hooks):
   ```bash
   herdr worktree remove --workspace "$OPEN_WS"
   ```
   If herdr refuses, report why; use `--force` only with explicit consent.
5. Delete the branch: `git -C "$REPO" branch -d "$BRANCH"`; on a squash merge `-d` refuses — then `-D`, once it's confirmed the PR was merged.

## list

`herdr worktree list --cwd "$REPO"` → table of entries with `is_linked_worktree: true`: branch, path, agent status (`herdr agent list`).
