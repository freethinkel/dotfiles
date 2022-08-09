local opts = {noremap = true, silent = true}
local keymap = vim.api.nvim_set_keymap

-- INSERT REMAP
keymap('i', 'jk', '<ESC>', opts)
keymap('i', 'jj', '<ESC>', opts)
keymap('i', 'kj', '<ESC>', opts)

vim.cmd "au BufNewFile,BufRead *.pcss set ft=postcss"
vim.cmd "au BufNewFile,BufRead *.mdx set ft=mdx"
