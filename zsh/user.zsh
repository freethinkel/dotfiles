# ─── User ZSH Overrides ──────────────────────────────────────────────
# This file is sourced at the end of .zshrc
# Add your personal aliases, functions, PATH modifications, etc.

# Example:
# alias vim='nvim'
# export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


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

[ -s "/Users/freethinkel/.bun/_bun" ] && source "/Users/freethinkel/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
