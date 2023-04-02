local M = {}

M.setup = function()
  local status, which_key = pcall(require, "which-key")
  if not status then
    return
  end

  which_key.setup()
end

M.register = function(config, opts)
  local status, wk = pcall(require, "which-key")
  if not status then
    return
  end
  wk.register(config, opts)
end

return M
