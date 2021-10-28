call plug#begin('~/.vim/plugged')
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
  Plug 'preservim/nerdtree'
  Plug 'aluriak/nerdcommenter'
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'airblade/vim-gitgutter'
  Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'ryanoasis/vim-devicons'

  Plug 'phanviet/vim-monokai-pro'
  Plug 'sainnhe/gruvbox-material'
  Plug 'junegunn/seoul256.vim'
	Plug 'morhetz/gruvbox'

  Plug 'pangloss/vim-javascript'
  Plug 'leafgarland/typescript-vim'
  Plug 'peitalin/vim-jsx-typescript'
  Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
  Plug 'vim-airline/vim-airline'
  Plug 'raimondi/delimitmate'
  Plug 'keith/swift.vim'
  Plug 'chun-yang/auto-pairs'
  Plug 'https://github.com/tpope/vim-fugitive'
	Plug 'mattn/emmet-vim'
	Plug 'vim-scripts/indentLine.vim'
	Plug 'evanleck/vim-svelte', {'branch': 'main'}
call plug#end()

command! -nargs=0 Prettier :CocCommand prettier.formatFile
let g:coc_global_extensions = [
\ 'coc-tsserver',
\ 'coc-flutter'
\ ]

if isdirectory('./node_modules') && isdirectory('./node_modules/prettier')
  let g:coc_global_extensions += ['coc-prettier']
endif

if isdirectory('./node_modules') && isdirectory('./node_modules/eslint')
  let g:coc_global_extensions += ['coc-eslint']
endif

source ~/.config/nvim/mappings.vim
source ~/.config/nvim/settings.vim

