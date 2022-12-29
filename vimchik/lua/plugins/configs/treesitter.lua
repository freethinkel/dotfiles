local M = {}

M.setup = function()
  local status, treesitter = pcall(require, "nvim-treesitter.configs")
  if not status then
    return
  end

  treesitter.setup({
    auto_install = true,
  })
end

return M
