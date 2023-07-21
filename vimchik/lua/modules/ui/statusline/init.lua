local M = {}

M.run = function()
  return require("modules.ui.statusline.vscode_mono").run()
end

return M
