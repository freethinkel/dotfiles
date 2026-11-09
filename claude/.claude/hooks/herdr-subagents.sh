#!/bin/sh
# PreToolUse on Agent|Workflow: inside herdr, subagents run as `claude` in a
# new herdr tab (skill herdr-agents), not in-process. Built-in skills like
# /code-review call the Agent tool directly, so CLAUDE.md alone doesn't hold.
# ponytail: web-fetch passes, it's the WebFetch stand-in, not a subagent.
[ "$HERDR_ENV" = 1 ] || exit 0
type=$(jq -r '.tool_input.subagent_type // empty')
[ "$type" = web-fetch ] && exit 0
jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
  permissionDecisionReason: "Inside herdr, subagents run as `claude` in a new herdr tab. Load the herdr-agents skill and start this same task there: one tab per agent, the same brief you would have given here, then wait and read its result."}}'
