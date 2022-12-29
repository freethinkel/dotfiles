local custom_colors = {
  diff_add = "#30383E",
  diff_delete = "#37222C",
  diff_change = "#333B56",
  diff_text = "#404D6F",
  error_unerline = "#d0524c",
  warn_unerline = "#f29639",
}

vim.cmd("hi DiffviewDiffAddAsDelete guifg=NONE guibg=" .. custom_colors.diff_delete)

vim.cmd("highlight DiagnosticUnderlineError cterm=undercurl gui=undercurl guisp=" .. custom_colors.error_unerline)
vim.cmd("highlight DiagnosticUnderlineWarn cterm=undercurl gui=undercurl guisp=" .. custom_colors.warn_unerline)
vim.cmd("highlight DiagnosticUnderlineInfo cterm=undercurl gui=undercurl")
vim.cmd("highlight DiagnosticUnderlineHint cterm=undercurl gui=undercurl")
