export ZSH="$HOME/.oh-my-zsh"

eval "$(starship init zsh)"

if [ -f ~/.env ]
then
  set -a; source ~/.env; set +a
fi

plugins=(
  git zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-z
)

source $ZSH/oh-my-zsh.sh

ZSH_DISABLE_COMPFIX="true"

# export DYLD_LIBRARY_PATH="$(brew - prefix)/lib:$DYLD_LIBRARY_PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$PATH:$HOME/fvm/default/bin:$HOME/.rvm/bin:$HOME/.dev/bin:$HOME/Library/Application Support/neovim/bin"
# alias dart="fvm dart"
# alias flutter="fvm flutter"

if [ -d "$HOME/.cargo" ]; 
then
  source $HOME/.cargo/env
fi

alias ssh_fix="eval \"$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519"
alias cls="clear"
alias lvim="$HOME/.local/bin/lvim"
alias vim="nvim"
alias vimconfig="vim ~/.config/nvim/"
alias v="vim"
alias :qa="exit"
alias :q="exit"
alias tdev="tmux new -s DEV || tmux attach-session -t DEV"
alias baresip="/opt/homebrew/Cellar/baresip/3.3.0/bin/baresip"
alias notes="cd /Users/freethinkel/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Mind\ palace/"
alias gp="git push origin HEAD"
alias ff="fvm flutter"

# bun completions
[ -s "/Users/freethinkel/.bun/_bun" ] && source "/Users/freethinkel/.bun/_bun"

# Bun
export BUN_INSTALL="/Users/freethinkel/.bun"
export EDITOR="nvim"

# pnpm
export PNPM_HOME="/Users/freethinkel/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

export WASMTIME_HOME="$HOME/.wasmtime"

export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$PATH":"$HOME/Library/Python/3.10/lib/python/site-packages"
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$WASMTIME_HOME/bin:$PATH"
export PATH="$PATH":"$HOME/.spicetify"
export PATH="$PATH:$HOME/Library/Python/3.11/lib/python/site-packages"
export PATH="$PATH:/usr/local/go/bin"
# OWN SCRIPTS
export PATH="$PATH":"$HOME/Developer/dev/dotfiles/bin"

 export LANG=en_US.UTF-8

[ -s "/Users/freethinkel/.bun/_bun" ] && source "/Users/freethinkel/.bun/_bun"

case `uname` in
  Darwin)
    alias ls="exa --icons"
    alias lst="ls --tree"
    alias cat="bat"
  ;;
  Linux)
    export TERM=xterm-256color

    if [ -d "$HOME/bin" ] ; then
        PATH="$HOME/bin:$PATH"
    fi

    if [ -d "$HOME/.local/bin" ] ; then
        PATH="$HOME/.local/bin:$PATH"
    fi
    export RAILS_ENV=development
    export GIT_SSH_VARIANT=ssh
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
    # commands for Linux go here
  ;;
  FreeBSD)
    # commands for FreeBSD go here
  ;;
esac

# Zellij stuff
#
zellij_tab_name_update() {
  if [[ -n $ZELLIJ ]]; then
    tab_name=''
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        tab_name+=$(basename "$(git rev-parse --show-toplevel)")/
        tab_name+=$(git rev-parse --show-prefix)
        tab_name=${tab_name%/}
    else
        tab_name=$PWD
            if [[ $tab_name == $HOME ]]; then
         	tab_name="~"
             else
         	tab_name=${tab_name##*/}
             fi
    fi
    command nohup zellij action rename-tab $tab_name >/dev/null 2>&1
  fi
}

zellij_tab_name_update
chpwd_functions+=(zellij_tab_name_update) # Run when path changes


# opencode
export PATH=/Users/freethinkel/.opencode/bin:$PATH
#compdef opencode
###-begin-opencode-completions-###
#
# yargs command completion script
#
# Installation: opencode completion >> ~/.zshrc
#    or opencode completion >> ~/.zprofile on OSX.
#
_opencode_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" opencode --get-yargs-completions "${words[@]}"))
  IFS=$si
  if [[ ${#reply} -gt 0 ]]; then
    _describe 'values' reply
  else
    _default
  fi
}
if [[ "'${zsh_eval_context[-1]}" == "loadautofunc" ]]; then
  _opencode_yargs_completions "$@"
else
  compdef _opencode_yargs_completions opencode
fi
###-end-opencode-completions-###

