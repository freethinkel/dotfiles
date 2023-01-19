local M = {}

M.setup = function()
  local status, alpha = pcall(require, "alpha")
  if not status then
    return
  end

  alpha.setup(require('alpha.themes.dashboard').config)
end

return M
