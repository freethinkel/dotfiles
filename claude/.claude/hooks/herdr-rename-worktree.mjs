#!/usr/bin/env bun
// Stop hook: rename an auto-named herdr worktree workspace to Claude's own session
// title (the "ai-title" record Claude Code writes into the transcript).
// Only touches labels herdr generated itself ("worktree-*"), so it fires once per
// worktree and never clobbers a manual rename.
import { readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";

const ws = process.env.HERDR_WORKSPACE_ID;
if (process.env.HERDR_ENV !== "1" || !ws) process.exit(0);

let transcript;
try {
  transcript = JSON.parse(readFileSync(0, "utf8")).transcript_path;
} catch {
  process.exit(0);
}
if (!transcript) process.exit(0);

// label first: one cheap CLI call, so the transcript is only read when we'd act on it
let label;
try {
  const out = execFileSync("herdr", ["workspace", "list"], { encoding: "utf8", timeout: 5000 });
  label = JSON.parse(out).result.workspaces.find((w) => w.workspace_id === ws)?.label ?? "";
} catch {
  process.exit(0);
}
if (!label.startsWith("worktree-")) process.exit(0);

let title;
try {
  title = readFileSync(transcript, "utf8")
    .split("\n")
    .findLast((l) => l.includes('"ai-title"'));
  title = title && JSON.parse(title).aiTitle;
} catch {
  process.exit(0);
}
// no title yet on the first turn — the next Stop picks it up
if (!title) process.exit(0);

try {
  execFileSync("herdr", ["workspace", "rename", ws, title], { timeout: 5000 });
} catch {}
