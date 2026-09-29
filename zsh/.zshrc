export EDITOR="${EDITOR:-nvim}"
export LANG="${LANG:-en_US.UTF-8}"
bindkey -e
typeset -U path  # nested shells re-add the same dirs

# repo/bin, wherever the repo lives: this file is a stow link into it
export PATH="${${(%):-%x}:A:h:h}/bin:$PATH"
# lazygit ignores ~/.config on macOS otherwise
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
# colors from `theme set`
[[ -f ~/.config/theme/lazygit.yml ]] && LG_CONFIG_FILE+=",$HOME/.config/theme/lazygit.yml"
[[ -f ~/.config/theme/fzf.zsh ]] && source ~/.config/theme/fzf.zsh

HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

for f in "$HOME/.config/zsh/lib/"*.zsh(N); do
    source "$f"
done

_antidote="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh"
[[ -f $_antidote ]] && source "$_antidote" && antidote load "$HOME/.config/zsh/plugins.txt"
unset _antidote
# after antidote so zsh-completions is on fpath
autoload -Uz compinit && compinit

command -v starship &>/dev/null && eval "$(starship init zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

alias obsidian="cd $HOME/Library/Mobile\ Documents/iCloud~md~obsidian/Documents"
alias notes="cd $HOME/Library/Mobile\ Documents/iCloud~Comma/Documents"

export BUN_INSTALL="$HOME/.bun"
# (N/): only dirs that exist
path=($BUN_INSTALL/bin(N/) $HOME/.opencode/bin(N/) $HOME/.nub/bin(N/) $HOME/zero/bin(N/) $path)
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# >>> otty shell integration >>>
# Added by Otty — toggle in Settings > Shell > Shell Integration.
# Inert unless launched by Otty (it sets $OTTY_SHELL_INTEGRATION).
if [ -n "$OTTY_SHELL_INTEGRATION" ] && [ -r "$OTTY_SHELL_INTEGRATION/otty-integration.zsh" ]; then
  . "$OTTY_SHELL_INTEGRATION/otty-integration.zsh"
fi
# <<< otty shell integration <<<
