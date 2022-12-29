#!/usr/bin/env sh

sketchybar --add item yabai_mode left                                      \
           --set yabai_mode                                                \
          background.padding_left=0                                        \
          background.padding_right=20                                       \
          background.height=20                                       \
          background.corner_radius=2                                       \
          background.color="$ACTIVE_COLOR"                                  \
          label="$(yabai -m query --spaces --space | jq -r '.type')"       \
          label.font="$FONT:Bold:14.0"                                      \
          label.color="$BACKGROUND_COLOR"                                             \
          label.y_offset=1                                             \
          label.padding_left=5                                             \
          label.padding_right=5                                            \
          update_freq=3                                                    \
          script="$PLUGIN_DIR/yabai_mode.sh"                               \
          --subscribe yabai_mode mouse.clicked
