export ZSH="/Users/freethinkel/.oh-my-zsh"

ZSH_THEME="spaceship"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

ZSH_DISABLE_COMPFIX="true"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$PATH:$HOME/.dev/flutter/bin:$HOME/.rvm/bin"

# MY ALIASES
alias cls="clear"
alias vimconfig="vim ~/.config/nvim/init.vim"
alias ls="exa"
alias lvim="/Users/freethinkel/.local/bin/lvim"
alias vim="lvim"
alias code="code-insiders"
source $HOME/.cargo/env
