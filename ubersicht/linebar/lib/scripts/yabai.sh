#!/bin/bash

yabai_path="/opt/homebrew/bin/yabai"
app_name="linebar"

if [ $? -eq 1 ]; then
  echo "yabaiError"
  exit 0
fi

$yabai_path -m signal --add event=space_changed action="osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"$app_name-index-jsx\"'" label="Refresh $app_name on space change"

$yabai_path -m signal --add event=space_changed action="osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"$app_name-index-jsx\"'" label="Refresh $app_name on space change"
$yabai_path -m signal --add event=display_changed action="osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"$app_name-index-jsx\"'" label="Refresh $app_name on display focus change"
$yabai_path -m signal --add event=window_focused action="osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"$app_name-index-jsx\"'" label="Refresh $app_name when focused application changes"
$yabai_path -m signal --add event=window_resized action="osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"$app_name-index-jsx\"'" label="Refresh $app_name when a window is resized"
$yabai_path -m signal --add event=application_front_switched action="osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"$app_name-index-jsx\"'" label="Refresh $app_name when front application switched application changes"
$yabai_path -m signal --add event=window_destroyed action="osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"$app_name-index-jsx\"'" label="Refresh $app_name when an application window is closed"
$yabai_path -m signal --add event=window_title_changed action="osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"$app_name-index-jsx\"'" label="Refresh $app_name when current window title changes"
