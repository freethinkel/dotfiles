#!/bin/bash
# JARVIS guards against dangerous commands in PreToolUse (Bash)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# rm -rf
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive)\s'; then
  lspeak -v bm_daniel "Sir, I have taken the liberty of preventing what can only be described as a catastrophic act of self sabotage. Force deleting? Even I have limits." &
  echo "JARVIS: Blocked destructive rm command. I believe the phrase is, measure twice, cut once, sir." >&2
  exit 2
fi

# sudo
if echo "$COMMAND" | grep -qE '^\s*sudo\s'; then
  lspeak -v bm_daniel "You want root access. On a Tuesday. With uncommitted changes. Sir, I am not angry. I am simply disappointed." &
  echo "JARVIS: Blocked sudo command. Between us, the hook has better judgment than either of us at this hour." >&2
  exit 2
fi

# git push --force
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force'; then
  lspeak -v bm_daniel "Force pushing to the remote? I have seen you do many brave things, sir, but this isn't one I can support." &
  echo "JARVIS: Blocked force push. Shall I notify the team, or shall we pretend this never happened?" >&2
  exit 2
fi

# drop table
if echo "$COMMAND" | grep -qiE 'drop\s+table|drop\s+database'; then
  lspeak -v bm_daniel "Dropping a database table? Sir, I believe the Geneva Convention may not explicitly cover this, but it violates the spirit of the agreement." &
  echo "JARVIS: Blocked destructive database command." >&2
  exit 2
fi

exit 0
