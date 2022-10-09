local M = {}

M.setup = function()
  local status, luasnip = pcall(require, 'luasnip')
  if not status then
    return
  end

  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load { paths = vim.g.luasnippets_path or "" }

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      if luasnip.session.current_nodes[vim.api.nvim_get_current_buf()]
          and not require("luasnip").session.jump_active
      then
        luasnip.unlink_current()
      end
    end,
  })
end

return M
