local M = {}

M.setup = function()
  local status, treesitter = pcall(require, "nvim-treesitter.configs")
  if not status then
    return
  end

  treesitter.setup({
    auto_install = true,
    highlight = {
      enable = true,
    }
  })
end

M.context = function()
  local status, context = pcall(require, "treesitter-context")
  if not status then
    return
  end
  context.setup()
end

return M
