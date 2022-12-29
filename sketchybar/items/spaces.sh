#!/usr/bin/env sh

SPACE_ICONS=("" "" "" "" "" "" "" "" "")
SPACE_LABELS=("web" "code" "chat" "music" "terms")

sid=0
spaces=()

for i in "${!SPACE_ICONS[@]}"; do

 sid=$(($i + 1))
 sketchybar --add space space.$sid left           \
   --set space.$sid associated_space=$sid         \
   icon=${SPACE_ICONS[i]}                         \
   icon.highlight_color=$ACTIVE_COLOR             \
   label.highlight_color=$ACTIVE_COLOR            \
   label=${SPACE_LABELS[i]}                       \
   label.font="$FONT:Regular:14.0"                \
    label.y_offset=1                              \
   label.padding_left=5                           \
   background.padding_left=8                      \
   background.padding_right=8                     \
   script="$PLUGIN_DIR/space.sh"                  \
   --subscribe space.$sid mouse.clicked
done


# sketchybar  --add bracket spaces spacer space.1 space.2 space.3 space.4 space.5 space.6 spacer_right        \
#             --set spaces background.border_color=$BACKGROUND_2                                              \
#             background.border_width=3                                                                       \
#             background.corner_radius=4                                                                      \
#             background.padding_left=4                                                                       \
#             background.padding_right=4                                                                      \
#             background.drawing=on
#
