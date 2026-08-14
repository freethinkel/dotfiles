#!/bin/bash
# Скрывает workspace-bar OmniWM, когда сфокусирован VMware Fusion.
# Запуск: omniwmctl watch focus --exec <этот файл>
CTL=/opt/homebrew/bin/omniwmctl
JQ=/opt/homebrew/bin/jq
LSAPP=/usr/bin/lsappinfo

# lsappinfo, а не omniwmctl query focused-window: Fusion не управляется OmniWM
# (float + свой нативный space), поэтому focused-window там всегда null.
front=$("$LSAPP" info -only bundleid "$("$LSAPP" front)")

want=true
case "$front" in *com.vmware.fusion*) want=false ;; esac

now=$("$CTL" query workspace-bar --format json | "$JQ" -r '.result.payload.monitors[0].isVisible')

[ "$now" = "$want" ] || "$CTL" command toggle-workspace-bar
