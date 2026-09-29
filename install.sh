#!/usr/bin/env bash
# Links the dotfiles into $HOME with stow, installs the Brewfile, the font and system defaults.
# macOS only. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")"

[[ $(uname) == Darwin ]] || { echo "macOS only" >&2; exit 1; }
command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh" >&2; exit 1; }

PACKAGES=(zsh git nvim tmux btop lazygit herdr claude ghostty skhd omniwm)

# a failed formula (e.g. an untrusted tap) should not stop the linking below
brew bundle --no-upgrade --file Brewfile || echo "brew bundle had errors, continuing" >&2

# configs that can't compute the repo path (.skhdrc) reach it through this link
ln -sfn "$PWD" ~/.dotfiles

# IoskeleyMono (ghostty, neovide); not in brew. A network hiccup only skips the font.
if ! ls ~/Library/Fonts/IoskeleyMono* &>/dev/null; then
  tmp=$(mktemp -d)
  if curl -fsSL -o "$tmp/f.zip" https://github.com/ahatem/IoskeleyMono/releases/download/v2.1.0/IoskeleyMono-NL-NerdFont.zip; then
    unzip -qo "$tmp/f.zip" -d "$tmp" && find "$tmp" -name '*.ttf' -exec cp {} ~/Library/Fonts/ \;
  else
    echo "font download failed, skipping" >&2
  fi
  rm -rf "$tmp"
fi

defaults write com.apple.dock autohide -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXPreferredViewStyle -string clmv
defaults write NSGlobalDomain _HIHideMenuBar -bool true # takes a relogin
mkdir -p ~/Pictures/screenshots && defaults write com.apple.screencapture location ~/Pictures/screenshots
killall Dock Finder SystemUIServer 2>/dev/null || true

mkdir -p ~/.claude ~/.config/herdr ~/.config/btop ~/.config/lazygit

stow --target "$HOME" --restow "${PACKAGES[@]}"

# tmux.conf runs tpm; it isn't in brew
[[ -d ~/.config/tmux/plugins/tpm ]] || git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm || echo "tpm clone failed" >&2

skhd --start-service 2>/dev/null || skhd --restart-service 2>/dev/null || true
open -ga OmniWM 2>/dev/null || true

# first run: no theme yet; otherwise just (re)link apps to the current one
if [[ -e ~/.config/theme/.current ]]; then bin/theme link; else bin/theme set snowfall-dark; fi
