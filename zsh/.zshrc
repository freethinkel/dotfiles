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
alias :qa="exit"
alias tdev="tmux new -s DEV || tmux attach-session -t DEV"
alias zr="zellij-runner"
alias colors="msgcat --color=test"

alias work="timer 45m && osascript -e 'display notification \"☕\" with title \"Work Timer is up!\" subtitle \"Take a Break 😊\" sound name \"Crystal\"' & say 'Все, адыхать. Попей водички там или сходи покури!'"
alias rest="timer 10m && osascript -e 'display notification \"☕\" with title \"Rest Timer is up!\" subtitle \"Take a Work 😊\" sound name \"Crystal\"' & say 'Все, теперб работать! впирьот, впирьот!'"

function pomo(){
  echo "How many rounds you want to do?"
  read count;
  for i in {1..$count};
  do
    work;
    sleep 1;
    rest;
  done
}

function gch() {
 git checkout "$(git branch --all | fzf | tr -d '[:space:]')"
}
# alias code="code-insiders"

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
export PATH="${PATH}:/Users/freethinkel/Library/Python/3.10/lib/python/site-packages"
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$WASMTIME_HOME/bin:$PATH"
