local utils = require("core.utils")

utils.load_mappings(nil, require("core.mappings"))
utils.setup_plugins(require("plugins"))
require("plugins.configs.lsp").setup_servers()

vim.cmd("au BufNewFile,BufRead *.pcss set ft=scss")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=mdx")

require("core.options")
require("core.ui")
utils.set_theme("oshmes-dark")
