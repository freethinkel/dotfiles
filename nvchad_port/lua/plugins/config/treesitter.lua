local M = {}

M.setup = function()
  local status, treesitter = pcall(require, 'nvim-treesitter.configs')
  if not status then
    return
  end

  treesitter.setup({
    ensure_installed = {
      "lua",
    },
    auto_install = true,
    highlight = {
      enable = true,
      use_languagetree = true,
    },

  })
end

return M
