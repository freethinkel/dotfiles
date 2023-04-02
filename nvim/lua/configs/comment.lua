local M = {}

M.setup = function()
  local status, comment = pcall(require, "Comment")
  if not status then
    return
  end

  comment.setup()
end

return M
