#!/usr/bin/env bash
# Keyboard layout as "EN"/"RU" from niri's event stream: waybar's niri/language
# fails with "argument not found" on per-layout format-<lang> labels (0.15).
exec niri msg -j event-stream | jq --unbuffered -rn '
  foreach inputs as $e ({names: [], idx: 0, changed: false};
    if $e.KeyboardLayoutsChanged then $e.KeyboardLayoutsChanged.keyboard_layouts as $k
      | {names: $k.names, idx: $k.current_idx, changed: true}
    elif $e.KeyboardLayoutSwitched then .idx = $e.KeyboardLayoutSwitched.idx | .changed = true
    else .changed = false end;
    select(.changed) | .names[.idx][0:2] | ascii_upcase)'
