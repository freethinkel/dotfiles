local M = {}

M.setup = function()
  local status, mason = pcall(require, 'mason')

  if not status then
    return
  end

  local options = {
    ensure_installed = require('core.utils').load_config().lsp.mason_install or {}
  }

  vim.api.nvim_create_user_command("MasonInstallAll", function()
    vim.cmd("MasonInstall " .. table.concat(options.ensure_installed, " "))
  end, {})

  mason.setup(options)
end

return M
