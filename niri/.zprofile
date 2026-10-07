# from the niri stow package (Arch only): logging in on tty1 starts the session
[[ -z $WAYLAND_DISPLAY && $XDG_VTNR == 1 ]] && exec niri-session
