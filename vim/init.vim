call plug#begin('~/.vim/plugged')
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'
	Plug 'airblade/vim-gitgutter'
	Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'ryanoasis/vim-devicons'
  Plug 'sickill/vim-monokai'
	Plug 'phanviet/vim-monokai-pro'
  Plug 'pangloss/vim-javascript'
  Plug 'leafgarland/typescript-vim'
  Plug 'peitalin/vim-jsx-typescript'
  Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
	Plug 'vim-airline/vim-airline'
	Plug 'raimondi/delimitmate'
	Plug 'keith/swift.vim'
	Plug 'chun-yang/auto-pairs'
	Plug 'https://github.com/tpope/vim-fugitive'
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

nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
imap jj <Esc>
nnoremap <silent> K :call CocAction('doHover')<CR>
nnoremap <C-m> :CocAction<CR>

set tabstop=2
set softtabstop=0 noexpandtab
set shiftwidth=2
set number
set hidden
set nobackup
set nowritebackup
set updatetime=300
set encoding=UTF-8
set cc=80
set ttyfast
set cmdheight=1
set mouse=a
set autoindent

syntax enable
colorscheme monokai_pro

let NERDTreeAutoDeleteBuffer=1
let NERDTreeShowHidden=1

let g:syntastic_swift_checkers = ['swiftpm', 'swiftlint']

" statusbar
let g:airline_powerline_fonts = 1 "Включить поддержку Powerline шрифтов
let g:airline#extensions#keymap#enabled = 0 "Не показывать текущий маппинг
let g:airline_section_z = "\ue0a1:%l/%L Col:%c" "Кастомная графа положения курсора
let g:Powerline_symbols='unicode' "Поддержка unicode
let g:airline#extensions#xkblayout#enabled = 0 "Про это позже расскажу

"Если вы используете обычную qwerty, то поменяте mac на win
set keymap=russian-jcukenmac
"Язык ввода при старте Вима - Английский
set iminsert=0
"Аналогично настраивается режим поиска
set imsearch=0
