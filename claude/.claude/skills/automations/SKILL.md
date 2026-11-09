---
name: automations
description: Prompts that run on a schedule, each as an agent in its own terminal. Use the `automations` CLI to read and change it.
---

# automations

Prompts that run on a schedule, each as an agent in its own terminal.

A local service with a page the user may have open; every command below talks to it and prints JSON, and the page updates as you change things. If a command says it isn't running, follow what it says.

## Commands

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" list`

List the automations

- `--json string`: the whole input as JSON (its fields win over the flags)

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" show`

Show one automation, as JSON that save takes back

- `--id string`: the automation's id, from list
- `--json string`: the whole input as JSON (its fields win over the flags)

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" save`

Add an automation, or replace one with --id: its name, prompt, folder and schedule (--kind interval|daily|once|cron)

- `--agent string`: claude (default) or codex
- `--at string`: daily: HH:MM
- `--backend string`: herdr, rex, hc or tmux; default: the one Shepherd shows
- `--base string`: the branch a worktree starts from; default: the folder's current one
- `--cron string`: cron: minute hour day month weekday
- `--days value`: daily: weekdays, 0 (Sunday) to 6, or mon..sun; default: every day (repeatable)
- `--dir string`: the folder or repository it runs in
- `--disabled `: save it turned off
- `--every int`: interval: minutes between runs
- `--grace int`: how many minutes late a missed run may still start (default 10)
- `--id string`: the automation to replace; leave out to add one
- `--json string`: the whole input as JSON (its fields win over the flags)
- `--kind string`: interval, daily, once or cron
- `--name string`: what it is called
- `--precheck string`: a shell command run before a scheduled run; exit 0 runs it
- `--prompt string`: the agent's first message
- `--run_at string`: once: YYYY-MM-DD HH:MM, local time
- `--timeout int`: the precheck's time limit in seconds (default 60)
- `--worktree `: a new worktree per run, branched from --base

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" enable`

Turn an automation on or off

- `--id string`: the automation's id
- `--json string`: the whole input as JSON (its fields win over the flags)
- `--on `: on; leave out to turn it off

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" remove`

Remove an automation and its history

- `--id string`: the automation's id
- `--json string`: the whole input as JSON (its fields win over the flags)

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" run`

Run an automation now, without its precheck

- `--id string`: the automation's id
- `--json string`: the whole input as JSON (its fields win over the flags)

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" runs`

An automation's runs, newest first (every automation's with no id)

- `--id string`: the automation's id
- `--json string`: the whole input as JSON (its fields win over the flags)

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" backend`

The backend runs go to when an automation names none: Shepherd's

- `--json string`: the whole input as JSON (its fields win over the flags)

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/automations/automations" projects`

The repositories the backend's terminals are in (Shepherd's backend with no --backend)

- `--backend string`: 
- `--json string`: the whole input as JSON (its fields win over the flags)
