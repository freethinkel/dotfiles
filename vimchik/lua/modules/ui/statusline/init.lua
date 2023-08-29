local M = {}

M.run = function()
  return require("modules.ui.statusline.vscode_colored").run()
end

return M
