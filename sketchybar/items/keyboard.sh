#!/usr/bin/env sh

sketchybar --add alias keyboard_layout right                               \
           --set keyboard_layout icon="􀂕"                                  \
                                icon.color=$TEXT_COLOR                     \
                                icon.y_offset=1                            \
                                background.padding_right=14                \
                                background.padding_left=7                  \
                                script="$PLUGIN_DIR/keyboard.sh"           \
                                update_freq=2                              \
                                --subscribe keyboard_layout mouse.clicked


