#!/bin/bash

sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE
/bin/bash -c ~/.config/aerospace/scripts/pip.sh
