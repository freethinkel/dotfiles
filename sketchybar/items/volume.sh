#!/usr/bin/env sh

# ICONS -> 
# 
# 
# 


sketchybar --add item volume right                              \
           --set volume script="$PLUGIN_DIR/volume.sh"          \
                        updates=on                              \
                        icon.background.drawing=on              \
                        icon.background.color=$ACTIVE_COLOR     \
                        icon.background.height=8                \
                        icon.width=0                            \
                        icon.align=right                        \
                        label.drawing=off                       \
                        background.drawing=on                   \
                        background.color=$BACKGROUND_COLOR      \
                        background.height=8                     \
                        background.padding_right=5              \
                        align=left                              \
           --subscribe volume volume_change

sketchybar --add item volume_icon right                           \
            --set volume_icon script="$PLUGIN_DIR/volume.sh"      \
            background.padding_right=10                           \
              icon=""                                            \
            icon.y_offset=1 


# sketchybar --add alias "Пункт управления,Sound" right                      \
#            --rename "Пункт управления,Sound" volume_alias                  \
#            --set volume_alias icon.drawing=off                           \
#                               label.drawing=off                          \
#                               alias.color=$TEXT_COLOR                         \
#                               background.padding_right=0                 \
#                               background.padding_left=-5                 \
#                               width=25                                   \
#                               align=right                                \
#                               click_script="$PLUGIN_DIR/volume_click.sh" 
