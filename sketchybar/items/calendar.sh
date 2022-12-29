#!/usr/bin/env sh

sketchybar --add item     calendar right                    \
           --set calendar icon=cal                          \
                          icon.font="$FONT:Regular:14.0"      \
                          icon.padding_right=10              \
                          label.align=right                 \
                          background.padding_left=0        \
                          background.padding_left=0        \
                          update_freq=30                    \
                          script="$PLUGIN_DIR/calendar.sh"  \
           --subscribe    calendar system_woke

