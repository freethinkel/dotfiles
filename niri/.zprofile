# from the niri stow package (Arch only): logging in on tty1 starts the session.
# -l: we already are a login shell; without it niri-session re-runs one, which reads this file again, forever
[[ -z $WAYLAND_DISPLAY && $XDG_VTNR == 1 ]] && exec niri-session -l
