---
name: pull-requests
description: Pull and merge requests of every repository you work in, on one page. Use the `pull-requests` CLI to read and change it.
---

# pull-requests

Pull and merge requests of every repository you work in, on one page.

A local service with a page the user may have open; every command below talks to it and prints JSON, and the page updates as you change things. If a command says it isn't running, follow what it says.

## Commands

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" list`

Pull requests of every repository, newest change first

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--limit int`: how many a repository, newest change first (30 by default)
- `--refresh `: ask the hosts again instead of the last minute's answer
- `--state string`: open (default), merged, closed or all

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" repos`

The repositories the list reads: the backend's terminals' and those added

- `--json string`: the whole input as JSON (its fields win over the flags)

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" add-repo`

Add a repository by its folder, its URL or host/owner/name

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--repo string`: a folder, a remote URL, or host/owner/name (github.com if no host)

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" remove-repo`

Remove a repository added by hand

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--repo string`: host/path, as repos lists it

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" close`

Close a pull or merge request

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--number int`: the PR's or MR's number
- `--repo string`: host/path, a PR's host and repo as list prints them

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" merge`

Merge a pull or merge request now

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--number int`: the PR's or MR's number
- `--repo string`: host/path, a PR's host and repo as list prints them

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" ready`

Mark a draft ready for review

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--number int`: the PR's or MR's number
- `--repo string`: host/path, a PR's host and repo as list prints them

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" close`

Close a pull or merge request

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--number int`: the PR's or MR's number
- `--repo string`: host/path, a PR's host and repo as list prints them

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" merge`

Merge a pull or merge request now

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--number int`: the PR's or MR's number
- `--repo string`: host/path, a PR's host and repo as list prints them

### `"/Users/freethinkel/Library/Application Support/Shepherd/extensions/pull-requests/pull-requests" ready`

Mark a draft ready for review

- `--json string`: the whole input as JSON (its fields win over the flags)
- `--number int`: the PR's or MR's number
- `--repo string`: host/path, a PR's host and repo as list prints them
