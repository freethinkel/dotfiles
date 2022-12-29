export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="spaceship"

SPACESHIP_CHAR_SYMBOL="❯ "

plugins=(
  git zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-z
)

source $ZSH/oh-my-zsh.sh

ZSH_DISABLE_COMPFIX="true"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$PATH:$HOME/.dev/flutter/bin:$HOME/.rvm/bin:$HOME/.dev/bin:$HOME/Library/Application Support/neovim/bin"

if [ -d "$HOME/.cargo" ]; 
then
  source $HOME/.cargo/env
fi

# MY ALIASES
alias ssh_fix="eval \"$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519"
alias cls="clear"
alias ls="exa"
alias lvim="$HOME/.local/bin/lvim"
alias vim="nvim"
alias vimconfig="vim ~/.config/nvim/"
alias v="vim"
alias cat="bat"
alias tdev="tmux new -s dev || tmux attach-session -t dev"

function gch() {
 git checkout "$(git branch --all | fzf | tr -d '[:space:]')"
}
# alias code="code-insiders"

# bun completions
[ -s "/Users/freethinkel/.bun/_bun" ] && source "/Users/freethinkel/.bun/_bun"

# Bun
export BUN_INSTALL="/Users/freethinkel/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="${PATH}:/Users/freethinkel/Library/Python/3.10/lib/python/site-packages"
export EDITOR="nvim"
