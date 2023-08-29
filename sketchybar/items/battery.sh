#!/usr/bin/env sh

# 

sketchybar --add item battery right                                                     \
           --set battery script="$PLUGIN_DIR/battery.sh"                                \
                                          update_freq=10                                \
                                          label=""                                     \
                                          icon.font="$FONT:Regular:14.0"                \
                                          label.font="$ICON_FONT:Regular:20.0"          \
                                          label.y_offset=1                              \
                                          icon.padding_right=10                          \
                                          background.padding_right=13                   \
                                          --subscribe battery mouse.clicked
