#!/usr/bin/env bash

MANAGED_EMOJIS=("⚡" "🔔" "✓")

set_status() {
  local emoji="$1"
  [ -z "${TMUX:-}" ] && return 0
  [ -z "${TMUX_PANE:-}" ] && return 0

  local current stripped e
  current=$(tmux display-message -p -t "$TMUX_PANE" '#W' 2>/dev/null) || return 0
  stripped="$current"
  for e in "${MANAGED_EMOJIS[@]}"; do
    stripped="${stripped#$e }"
    stripped="${stripped#$e}"
  done

  if [ -n "$emoji" ]; then
    tmux rename-window -t "$TMUX_PANE" "$emoji $stripped" 2>/dev/null
  else
    tmux rename-window -t "$TMUX_PANE" "$stripped" 2>/dev/null
  fi
}

UserPromptSubmit() { set_status "⚡"; }
PreToolUse()       { set_status "⚡"; }
Notification()     { set_status "🔔"; }
Stop()             { set_status "✓"; }

case "${1:-}" in
UserPromptSubmit) UserPromptSubmit ;;
PreToolUse)       PreToolUse ;;
Stop)             Stop ;;
Notification)     Notification ;;
*)
  echo "Unknown command: ${1:-}" >&2
  exit 1
  ;;
esac
