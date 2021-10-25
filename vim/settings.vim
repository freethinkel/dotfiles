set tabstop=2
set softtabstop=0 noexpandtab
set shiftwidth=2
set number
set hidden
set nobackup
set nowritebackup
set updatetime=100
set encoding=UTF-8
set cc=80
set ttyfast
set cmdheight=1
set mouse=a
set autoindent
set scrolloff=20

syntax enable

set termguicolors
set background=dark
let g:gruvbox_material_background = 'soft'
let g:gruvbox_material_enable_italic = 1
let g:gruvbox_material_disable_italic_comment = 0
let g:gruvbox_material_palette = 'original'
let g:gruvbox_material_diagnostic_line_highlight = 1
let g:airline_theme = 'gruvbox_material'
let g:gitgutter_sign_added = '│'
let g:gitgutter_sign_removed = '│'
let g:gitgutter_sign_modified = '│'
let g:gitgutter_sign_removed_first_line = '│'
let g:gitgutter_sign_removed_above_and_below = '│'
let g:gitgutter_sign_modified_removed = '│'
colorscheme gruvbox-material

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
set list
set listchars=tab:\┆\ 
