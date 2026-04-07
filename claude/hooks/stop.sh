#!/bin/bash
# Capture current pane target at the moment the hook fires
TARGET=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')

terminal-notifier \
  -title "Claude Code" \
  -message "Done" \
  -execute "tmux select-window -t '$TARGET' && open -a Ghostty"
