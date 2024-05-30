local opt = vim.opt

vim.g.mapleader = " "

-- Undercurl
-- vim.cmd([[let &t_Cs = "\e[60m"]])
-- vim.cmd([[let &t_Ce = "\e[24m"]])
-- " Inform vim how to enable undercurl in wezterm
-- let &t_Cs = "\e[60m"
-- " Inform vim how to disable undercurl in wezterm (this disables all underline modes)
-- let &t_Ce = "\e[24m"

opt.so = 15
opt.pumheight = 10

opt.swapfile = false
opt.wrap = false

-- opt.relativenumber = true

opt.laststatus = 3 -- global statusline
opt.showmode = false

opt.clipboard = "unnamedplus"
opt.cursorline = true

-- Indenting
opt.expandtab = true
opt.shiftwidth = 2
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 2

opt.fillchars = { eob = " " }
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

-- Numbers
opt.number = true
opt.numberwidth = 2
opt.ruler = false

-- disable nvim intro
opt.shortmess:append("sI")

opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 200
opt.undofile = true

opt.splitright = true
opt.splitbelow = true

-- opt.list = true
-- opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

opt.inccommand = "split"
opt.hlsearch = true

-- interval for writing swap file to disk, also used by gitsigns
opt.updatetime = 250

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append("<>[]hl")
