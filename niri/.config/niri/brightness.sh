#!/usr/bin/env bash
# brightness.sh +10|-10: step the backlight by percent through logind, so no root or udev rule is needed.
dev=$(ls /sys/class/backlight | head -1)
max=$(< /sys/class/backlight/$dev/max_brightness)
cur=$(< /sys/class/backlight/$dev/brightness)
new=$(( cur + max * $1 / 100 ))
(( new > max )) && new=$max
(( new < max / 100 )) && new=$(( max / 100 ))
busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto \
  org.freedesktop.login1.Session SetBrightness ssu backlight "$dev" "$new"
