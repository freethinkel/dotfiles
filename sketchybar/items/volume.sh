#!/usr/bin/env sh

sketchybar --add item volume right                              \
           --set volume script="$PLUGIN_DIR/volume.sh"          \
                        updates=on                              \
                        icon.background.drawing=on              \
                        icon.background.color=$ACTIVE_COLOR     \
                        icon.background.height=8                \
                        icon.width=0                            \
                        icon.align=right                        \
                        label.drawing=off                       \
                        background.corner_radius=3              \
                        icon.background.corner_radius=3         \
                        background.drawing=on                   \
                        background.color=$BACKGROUND_COLOR      \
                        background.height=8                     \
                        background.padding_right=5              \
                        align=left                              \
           --subscribe volume volume_change

sketchybar --add item volume_icon right                           \
            --set volume_icon script="$PLUGIN_DIR/volume.sh"      \
            background.padding_right=10                           \
            icon="􀊥"                                              \
            icon.font="$ICON_FONT:Regular:18.0"                   \
            script="$PLUGIN_DIR/volume.sh"                        \
            updates=on \
            icon.y_offset=1 

