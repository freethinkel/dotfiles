#!/usr/bin/env sh

sketchybar --add alias keyboard_layout right                               \
           --set keyboard_layout icon.drawing=off                          \
                                label="A"                                  \
                                label.font="$FONT:Bold:13.0"               \
                                label.color="$BACKGROUND_COLOR"            \
                                label.y_offset=1                          \
                                background.color="$TEXT_COLOR"             \
                                background.corner_radius=2                 \
                                background.height=19                       \
                                background.padding_right=10                \
                                width=19                                   \
                                align=center                               

