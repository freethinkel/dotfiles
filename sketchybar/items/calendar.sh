#!/usr/bin/env sh

sketchybar --add item     calendar right                           \
           --set calendar icon=cal                                 \
                          icon.font="$FONT:Regular:14.0"           \
                          background.padding_right=5               \
                          icon.padding_right=10                    \
                          icon.padding_left=10                     \
                          label.padding_right=10                   \
                          label.font="$FONT:Bold:14.0"             \
                          label.align=right                        \
                          label.color="$ACTIVE_COLOR"              \
                          update_freq=30                           \
                          script="$PLUGIN_DIR/calendar.sh"         \
           --subscribe    calendar system_woke

sketchybar --add item     calendar_icon right                      \
           --set calendar_icon icon="􀉉"                            \
                          background.padding_left=5

sketchybar --add item calendar_spacer right                        \
           --set calendar_spacer background.padding_left=20

sketchybar --add bracket date_time calendar calendar_icon          \
           --set date_time background.color="$BACKGROUND_COLOR"     \
                          background.corner_radius=$BORDER_RADIUS  \
                          background.border_width=1                \
                          background.border_color="$BORDER_COLOR"  \
