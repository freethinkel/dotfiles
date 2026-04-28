# ─── User Meta ────────────────────────────────────────────────────────
# Sourced early by slicker. Export machine-specific variables here.
# This allows base configs to branch on MACHINE for work/home differences.

# Set to "work" or "home" (or any label you like)
export MACHINE="home"

# export GIT_AUTHOR_NAME="Your Name"
# export SLICKER_THEME="dark"

# ─── Starship override ───────────────────────────────────────────────
# Use user starship.toml instead of slicker default if it exists
_user_starship="$SLICKER_ROOT/user/zsh/starship.toml"
if [[ -f "$_user_starship" ]]; then
  export STARSHIP_CONFIG="$_user_starship"
fi
unset _user_starship
