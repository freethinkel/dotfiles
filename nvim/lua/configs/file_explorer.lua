local M = {}

M.setup = function()
  require("neo-tree").setup({
    default_component_configs = {
      indent = {
        padding = 0,
      },
      icon = {
        folder_closed = "",
        folder_open = "",
        folder_empty = "",
        default = "",
      },
      git_status = {
        symbols = {
          added = "",
          deleted = "",
          modified = "",
          renamed = "➜",
          untracked = "",
          ignored = "",
          unstaged = "",
          staged = "✓",
          conflict = "",
        },
      },
    },
  })
end

return M
