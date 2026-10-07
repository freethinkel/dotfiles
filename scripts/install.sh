#!/usr/bin/env bash
# Links the dotfiles into $HOME with stow. macOS: also the Brewfile, the font and system defaults.
# Linux: CLI packages only. Plain Arch: arch.pkgs plus the niri desktop;
# Omarchy/Asahi: tools from pacman, its own configs moved to *.bak;
# servers: tools as release binaries in ~/.local/bin. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

PACKAGES=(zsh git nvim tmux btop lazygit herdr claude)

# configs that can't compute the repo path (.skhdrc) reach it through this link
ln -sfn "$PWD" ~/.dotfiles

if [[ $(uname) == Darwin ]]; then
PACKAGES+=(ghostty skhd omniwm)
command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh" >&2; exit 1; }

# a failed formula (e.g. an untrusted tap) should not stop the linking below
brew bundle --no-upgrade --file Brewfile || echo "brew bundle had errors, continuing" >&2
fonts=~/Library/Fonts

defaults write com.apple.dock autohide -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXPreferredViewStyle -string clmv
defaults write NSGlobalDomain _HIHideMenuBar -bool true # takes a relogin
mkdir -p ~/Pictures/screenshots && defaults write com.apple.screencapture location ~/Pictures/screenshots
killall Dock Finder SystemUIServer 2>/dev/null || true
elif [[ ! -d ~/.local/share/omarchy ]] && grep -qx 'ID=arch' /etc/os-release 2>/dev/null; then
# plain Arch (the T14): CLI tools and the niri desktop from arch.pkgs
PACKAGES+=(ghostty niri waybar)
fonts=~/.local/share/fonts
# -Syu, never -Sy alone: Arch doesn't support partial upgrades. Unquoted on purpose, one word per package.
sudo pacman -Syu --needed --noconfirm $(sed 's/#.*//' arch.pkgs)
sudo systemctl enable --now NetworkManager power-profiles-daemon fstrim.timer
# AUR with plain makepkg (paru-bin lags behind pacman's libalpm and won't start),
# rebuilt only when the AUR version moved, so a re-run also upgrades.
# ponytail: a package with an epoch never matches and rebuilds every run
for p in helium-browser-bin; do
  d=~/.cache/aur/$p
  if [[ -d $d ]]; then git -C "$d" pull -q; else git clone -q "https://aur.archlinux.org/$p.git" "$d"; fi ||
    { echo "$p: fetch failed" >&2; continue; }
  v=$(sed -n 's/^\tpkgver = //p; s/^\tpkgrel = //p' "$d/.SRCINFO" | paste -sd-)
  [[ $(pacman -Q "$p" 2>/dev/null) == "$p $v" ]] && continue
  # makepkg checks release signatures against validpgpkeys (full fingerprints) but won't fetch the keys
  gpg -q --keyserver hkps://keyserver.ubuntu.com --recv-keys $(sed -n 's/^\tvalidpgpkeys = //p' "$d/.SRCINFO") || true
  (cd "$d" && makepkg -si --noconfirm) || echo "$p: build failed" >&2
done
[[ $SHELL == */zsh ]] || chsh -s "$(command -v zsh)" || echo "chsh failed, switch to zsh by hand" >&2
[[ -d ~/.antidote ]] || git clone --depth 1 https://github.com/mattmc3/antidote ~/.antidote || echo "antidote clone failed" >&2
elif command -v pacman >/dev/null; then
# Omarchy, Asahi (where the x86_64 release binaries below don't run)
sudo pacman -S --needed --noconfirm stow zsh tmux neovim starship zoxide fzf ripgrep fd bat eza lazygit git-delta btop
[[ $SHELL == */zsh ]] || chsh -s "$(command -v zsh)" || echo "chsh failed, switch to zsh by hand" >&2
[[ -d ~/.antidote ]] || git clone --depth 1 https://github.com/mattmc3/antidote ~/.antidote || echo "antidote clone failed" >&2
else
# No brew and no sudo on a server: latest release binaries into ~/.local/bin.
# git, stow, zsh, tmux and nvim are expected from the system.
# ponytail: x86_64 only, never upgrades what is already there (rm the binary to refetch);
# sesh and fzf-tmux (tmux prefix+T) are skipped
mkdir -p ~/.local/bin
gh_bin() { # <owner/repo> <binary>
  [[ -x ~/.local/bin/$2 ]] && return
  local url tmp
  url=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep -o 'https://[^"]*' |
    grep -E 'x86_64.*linux-musl\.(tar\.gz|tbz)$|linux_amd64\.tar\.gz$|[Ll]inux_x86_64\.tar\.gz$' | head -1) || true
  [[ $url ]] || { echo "$2: no release asset found, skipping" >&2; return; }
  tmp=$(mktemp -d)
  if curl -fsSL -o "$tmp/a" "$url" && tar -xf "$tmp/a" -C "$tmp"; then
    install -m 755 "$(find "$tmp" -type f -name "$2" | head -1)" ~/.local/bin/ || echo "$2: install failed" >&2
  else
    echo "$2: download failed, skipping" >&2
  fi
  rm -rf "$tmp"
}
gh_bin starship/starship starship
gh_bin ajeetdsouza/zoxide zoxide
gh_bin junegunn/fzf fzf
gh_bin BurntSushi/ripgrep rg
gh_bin sharkdp/fd fd
gh_bin sharkdp/bat bat
gh_bin eza-community/eza eza
gh_bin jesseduffield/lazygit lazygit
gh_bin dandavison/delta delta
gh_bin aristocratos/btop btop
[[ -d ~/.antidote ]] || git clone --depth 1 https://github.com/mattmc3/antidote ~/.antidote || echo "antidote clone failed" >&2
fi

# IoskeleyMono (ghostty, neovide); not in brew or pacman. A network hiccup only skips the font.
if [[ ${fonts-} ]] && ! ls "$fonts"/IoskeleyMono* &>/dev/null; then
  mkdir -p "$fonts"
  tmp=$(mktemp -d)
  if curl -fsSL -o "$tmp/f.zip" https://github.com/ahatem/IoskeleyMono/releases/download/v2.1.0/IoskeleyMono-NL-NerdFont.zip; then
    unzip -qo "$tmp/f.zip" -d "$tmp" && find "$tmp" -name '*.ttf' -exec cp {} "$fonts"/ \;
  else
    echo "font download failed, skipping" >&2
  fi
  rm -rf "$tmp"
fi

mkdir -p ~/.claude ~/.config/herdr ~/.config/btop ~/.config/lazygit

# Linux distros (Omarchy) ship their own configs: move them aside instead of letting stow abort.
# A whole nvim dir goes, leftover LazyVim plugin files would load alongside ours.
if [[ $(uname) == Linux ]]; then
  [[ -d ~/.config/nvim && ! -L ~/.config/nvim ]] && mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s)
  for p in "${PACKAGES[@]}"; do
    (cd "$p" && find . -type f -o -type l) | while read -r f; do
      t=~/${f#./}
      # already ours, maybe through a folded dir symlink: leave it
      [[ -e $t && $(readlink -f "$t") != "$PWD/$p/${f#./}" ]] && mv "$t" "$t.bak" || true
    done
  done
fi

stow --target "$HOME" --restow "${PACKAGES[@]}"

# tmux.conf runs tpm; it isn't in brew
[[ -d ~/.config/tmux/plugins/tpm ]] || git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm || echo "tpm clone failed" >&2

if [[ $(uname) == Darwin ]]; then
  skhd --start-service 2>/dev/null || skhd --restart-service 2>/dev/null || true
  open -ga OmniWM 2>/dev/null || true
  statusbar/build.sh || echo "statusbar build failed" >&2
  # Home Assistant VM: only on the Mac that has it
  if [[ -d ~/Library/Containers/com.utmapp.UTM/Data/Documents/homeassistant.utm ]]; then
    cp scripts/homeassistant.plist ~/Library/LaunchAgents/
    launchctl bootstrap "gui/$UID" ~/Library/LaunchAgents/homeassistant.plist 2>/dev/null || true
  fi
fi

# first run: no theme yet; otherwise just (re)link apps to the current one
if [[ -e ~/.config/theme/.current ]]; then bin/theme link; else bin/theme set snowfall-dark; fi
