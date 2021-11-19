#!/usr/bin/env bash
TITLE=mylauncher

alacritty -t "${TITLE}" -o window.dimensions.lines=35 -o window.dimensions.columns=80 -o window.decorations=none --working-directory "$(pwd)" -e "$1"

