#!/usr/bin/env sh

sketchybar --add item caffeinate right                          \
          --set caffeinate                                      \
          update_freq=10                                        \
          script="$PLUGIN_DIR/caffeinate.sh"                    \
          background.padding_right=10                           \
          icon.y_offset=1                                       \
          --subscribe caffeinate mouse.clicked
