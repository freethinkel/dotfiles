local cmd = vim.cmd             -- execute Vim commands
local exec = vim.api.nvim_exec  -- execute Vimscript
local g = vim.g                 -- global variables
local opt = vim.opt             -- global/buffer/windows-scoped options

-----------------------------------------------------------
-- Главные
-----------------------------------------------------------
opt.colorcolumn = '80'              -- Разделитель на 80 символов
opt.cursorline = true               -- Подсветка строки с курсором
opt.spelllang= { 'en_us', 'ru' }    -- Словари рус eng
opt.number = true                   -- Включаем нумерацию строк
-- opt.relativenumber = true           -- Вкл. относительную нумерацию строк
opt.so = 20                           -- Курсор всегда в центре экрана
opt.undofile = true                 -- Возможность отката назад
opt.splitright = true               -- vertical split вправо
opt.splitbelow = true               -- horizontal split вниз
opt.mouse = 'a'                     -- Поддержка мыши
opt.hidden = true
opt.timeoutlen = 300
opt.smartindent = true

vim.g.mapleader = " "               -- leader key

-----------------------------------------------------------
-- Цветовая схема
-----------------------------------------------------------
opt.termguicolors = true      --  24-bit RGB colors
cmd'colorscheme catppuccin'

-----------------------------------------------------------
-- Форматирование
-----------------------------------------------------------

cmd [[ autocmd BufWritePre *.ts lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.tsx lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.js lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.css lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.scss lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.sss lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.postcss lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.svelte lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
cmd [[ autocmd BufWritePre *.html lua vim.lsp.buf.formatting_sync(nil, 1000) ]]

-----------------------------------------------------------
-- Табы и отступы
-----------------------------------------------------------
cmd([[
filetype indent plugin on
syntax enable
]])
opt.expandtab = true      -- use spaces instead of tabs
opt.shiftwidth = 2        -- shift 4 spaces when tab
opt.tabstop = 2           -- 1 tab == 4 spaces
opt.smartindent = true    -- autoindent new lines
-- don't auto commenting new lines
cmd [[au BufEnter * set fo-=c fo-=r fo-=o]]
cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]

-----------------------------------------------------------
-- Установки для плагинов
-----------------------------------------------------------
