## Deep Code Review

Perform a thorough, multi-stage code review using parallel agents. Only flag HIGH SIGNAL issues — objective bugs, security vulnerabilities, and clear CLAUDE.md/AGENTS.md violations.

### Step 0: Detect Platform

Before anything else, determine whether this is a GitHub or GitLab repository:

Run `git remote get-url origin` and inspect the URL:
- If it contains `github.com` → use `gh` CLI for all interactions
- If it contains `gitlab.com` (or any GitLab instance) → use `glab` CLI for all interactions

Store this as the `CLI_TOOL` (`gh` or `glab`) for all subsequent steps.

### Step 1: Gather Context (parallel)

Launch these tasks in parallel:

**Agent A (Explore):** Find all relevant CLAUDE.md and AGENTS.md files:
- The root CLAUDE.md, if it exists
- Any CLAUDE.md or AGENTS.md files in directories containing modified files
- Return only file paths and their contents

**Agent B (Explore):** If this workspace has an associated MR/PR, use the detected CLI tool to read the title and description (not the full diff):
- GitHub: `gh pr view`
- GitLab: `glab mr view`
Return the title, description, and MR/PR number.

**Bash:** Run `git diff HEAD` (or `git diff main...HEAD` if on a feature branch) to capture the full changeset.

### Step 2: Summarize Changes

Launch one general-purpose agent to read the diff and return a concise summary of all changes — what was added, modified, and removed, grouped by area of concern.

### Step 3: Review (4 parallel agents)

Launch 4 agents in parallel. Provide each agent with: the diff, the change summary from Step 2, PR title/description (if available), and relevant CLAUDE.md/AGENTS.md contents. Instruct each agent to return a structured list of issues (description, location, reason) and to NOT post any comments.

**Agent 1 (general-purpose):** CLAUDE.md/AGENTS.md compliance — Audit the first half of changed files for violations. Only consider CLAUDE.md/AGENTS.md files that share a file path or are parents of the changed file.

**Agent 2 (general-purpose):** CLAUDE.md/AGENTS.md compliance — Audit the second half of changed files. Same scoping rules as Agent 1.

**Agent 3 (general-purpose):** Bug detection (diff-only) — Scan for obvious bugs by looking only at the diff. Flag only significant bugs. Do not flag issues that cannot be validated without context outside the diff.

**Agent 4 (general-purpose):** Deep bug detection — Look for problems in the introduced code by reading surrounding context as needed. Check for security issues, incorrect logic, race conditions, null safety, error handling gaps, and edge cases.

### Step 4: Validate Issues (parallel agents)

For each issue found in Step 3, launch a parallel validation agent:

- Provide the issue description, file path, and relevant code context
- The agent must verify the issue is real by reading the actual code
- For CLAUDE.md violations: confirm the rule exists, is scoped to this file, and is actually violated
- For bugs: confirm the bug can actually occur at runtime given the surrounding code
- Each agent returns: `CONFIRMED` or `REJECTED` with reasoning

### Step 5: Filter and Report

Discard all `REJECTED` issues. With the remaining confirmed issues:

1. If a PR/MR exists, post inline review comments using the detected CLI tool:
   - GitHub: `gh api repos/{owner}/{repo}/pulls/{pr_number}/comments`
   - GitLab: `glab mr note {mr_number}` or `glab api projects/{project_id}/merge_requests/{mr_iid}/discussions`
   Post ONE comment per unique issue, at the relevant line.

2. Output a formatted summary:

```
### Review Results

#### #1 [Category] Issue title
Description of the issue.
**File:** `path/to/file.ts:42`
**Severity:** high | medium

#### #2 [Category] Issue title
...
```

### What to flag

- Objective bugs that will cause incorrect behavior at runtime
- Security vulnerabilities (injection, XSS, auth bypass, etc.)
- Clear, unambiguous CLAUDE.md/AGENTS.md violations (quote the exact rule)
- Resource leaks, race conditions, data loss scenarios

### What NOT to flag (false positives)

- Pre-existing issues not introduced by this diff
- Subjective concerns, style preferences, or "suggestions"
- Issues a linter would catch
- Potential issues that "might" be problems — if you're not certain, skip it
- General code quality concerns unless explicitly required by CLAUDE.md/AGENTS.md
- Pedantic nitpicks a senior engineer would ignore
- Issues explicitly silenced in code (e.g., lint-ignore comments)

### Rules

- Only the main orchestrator posts comments — subagents must never post comments directly
- Do not use AskUserQuestion — complete the entire review autonomously
- Use `gh` CLI for GitHub repos and `glab` CLI for GitLab repos (detect from remote URL in Step 0)
- Cite and link each issue in inline comments (e.g., link to the CLAUDE.md rule being violated)
- If no issues are found, report a clean review
