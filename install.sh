#!/usr/bin/env bash
# Links the dotfiles into $HOME with stow. On macOS also installs the Brewfile, the font and system defaults.
# Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")"

# terminal stuff, every machine
PACKAGES=(zsh git nvim tmux zellij btop lazygit herdr claude)

if [[ $(uname) == Darwin ]]; then
  PACKAGES+=(ghostty skhd omniwm sketchybar yabai aerospace borders)
  # a failed formula (e.g. an untrusted tap) should not stop the linking below
  brew bundle --no-upgrade --file Brewfile || echo "brew bundle had errors, continuing" >&2

  # IoskeleyMono (ghostty, neovide); not in brew
  if ! ls ~/Library/Fonts/IoskeleyMono* &>/dev/null; then
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/f.zip" https://github.com/ahatem/IoskeleyMono/releases/download/v2.1.0/IoskeleyMono-NL-NerdFont.zip
    unzip -qo "$tmp/f.zip" -d "$tmp" && find "$tmp" -name '*.ttf' -exec cp {} ~/Library/Fonts/ \;
    rm -rf "$tmp"
  fi

  defaults write com.apple.dock autohide -bool false
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder FXPreferredViewStyle -string clmv
  mkdir -p ~/Pictures/screenshots && defaults write com.apple.screencapture location ~/Pictures/screenshots
fi

# These dirs also hold runtime state: keep them real so stow links single files into them
# instead of folding the whole dir into the repo.
mkdir -p ~/.claude ~/.config/herdr ~/.config/zellij ~/.config/btop ~/.config/lazygit

stow --target "$HOME" --restow "${PACKAGES[@]}"

# first run: no theme yet; otherwise just (re)link apps to the current one
if [[ -e ~/.config/theme/.current ]]; then bin/theme link; else bin/theme set snowfall-dark; fi
