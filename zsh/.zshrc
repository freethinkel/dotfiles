export EDITOR="${EDITOR:-nvim}"
export LANG="${LANG:-en_US.UTF-8}"
bindkey -e

export PATH="$HOME/Developer/infra/dotfiles/bin:$PATH"
# lazygit ignores ~/.config on macOS otherwise
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"

HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

for f in "$HOME/.config/zsh/lib/"*.zsh(N); do
    source "$f"
done

# antidote: brew on the mac, the distro package or a nix profile on linux
for _antidote in \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh" \
    /usr/share/zsh-antidote/antidote.zsh \
    "$HOME/.nix-profile/share/antidote/antidote.zsh"; do
    if [[ -f $_antidote ]]; then
        source "$_antidote"
        break
    fi
done
unset _antidote
(( $+functions[antidote] )) && antidote load "$HOME/.config/zsh/plugins.txt"

command -v starship &>/dev/null && eval "$(starship init zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

alias obsidian="cd $HOME/Library/Mobile\ Documents/iCloud~md~obsidian/Documents"
alias notes="cd $HOME/Library/Mobile\ Documents/iCloud~Comma/Documents"

# Собрать Xcode-проект из текущей папки и поставить на подключённый iPhone.
# Схему можно передать аргументом, иначе берётся первая из xcodebuild -list.
ios-install() {
    emulate -L zsh
    setopt local_options null_glob

    local ws=(*.xcworkspace) proj=(*.xcodeproj)
    local -a target
    if (( $#ws )); then
        target=(-workspace $ws[1])
    elif (( $#proj )); then
        target=(-project $proj[1])
    else
        echo "ios-install: в $PWD нет .xcodeproj или .xcworkspace" >&2
        return 1
    fi

    # Первое устройство в состоянии connected; UDID вытаскиваем регуляркой,
    # потому что колонки в выводе devicectl выровнены пробелами и разъезжаются
    local device=$(xcrun devicectl list devices 2>/dev/null \
        | grep -w 'available' \
        | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' \
        | head -1)
    if [[ -z $device ]]; then
        echo "ios-install: подключённых устройств нет (xcrun devicectl list devices)" >&2
        return 1
    fi

    local scheme=${1:-$(xcodebuild $target -list 2>/dev/null \
        | awk '/Schemes:/{f=1;next} f&&NF{print;exit}' | xargs)}
    if [[ -z $scheme ]]; then
        echo "ios-install: не удалось определить схему, передай её аргументом" >&2
        return 1
    fi

    echo "→ $scheme на устройство $device"
    xcodebuild $target -scheme "$scheme" -configuration Debug \
        -destination "id=$device" -derivedDataPath build \
        -allowProvisioningUpdates build || return 1

    local app=(build/Build/Products/Debug-iphoneos/*.app)
    if (( ! $#app )); then
        echo "ios-install: сборка не оставила .app" >&2
        return 1
    fi

    xcrun devicectl device install app --device "$device" "$app[1]" || return 1
    # Идентификатор берём из собранного бандла, а не из настроек проекта:
    # он уже с подставленными переменными
    local bundle=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app[1]/Info.plist")
    xcrun devicectl device process launch --device "$device" "$bundle"
}

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.nub/bin:$PATH"
export PATH="$HOME/zero/bin:$PATH"

# >>> otty shell integration >>>
if [ -n "$OTTY_SHELL_INTEGRATION" ] && [ -r "$OTTY_SHELL_INTEGRATION/otty-integration.zsh" ]; then
  . "$OTTY_SHELL_INTEGRATION/otty-integration.zsh"
fi
# <<< otty shell integration <<<
