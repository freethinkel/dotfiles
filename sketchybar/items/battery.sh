#!/usr/bin/env sh

# 

sketchybar --add item battery right                                                     \
           --set battery script="$PLUGIN_DIR/battery.sh"                                \
                                          update_freq=10                                \
                                          icon=""                                      \
                                          icon.font="$ICON_FONT:Regular:20.0"           \
                                          icon.y_offset=1                               \
                                          background.padding_right=13                   \
                                          --subscribe battery mouse.clicked