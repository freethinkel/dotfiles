local M = {}


M.setup = function()
  local status, outline = pcall(require, "symbols-outline")
  if not status then
    return
  end

  outline.setup()
end

return M
