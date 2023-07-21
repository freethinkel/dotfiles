local module = {}

module.setup = function()
  local get_hl = require("core.utils").get_hl

  local M = {}

  M.neotree = {
    NeoTreeDirectoryIcon = get_hl("NeoTreeFadeText1")
  }

  VertSplit = { fg = get_hl("Normal").bg }
  M.theme = {
  }

  M.tabufline = {
    -- TbLineBufOn = get_hl("BufferCurrent")
  }

  vim.cmd("au BufNewFile,BufRead *.pcss set ft=scss")
  vim.cmd("au BufNewFile,BufRead *.mdx set ft=mdx")
  return M
end


return module
