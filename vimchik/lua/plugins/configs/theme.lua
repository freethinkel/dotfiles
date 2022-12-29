local M = {}

M.rose_pine = function()
  local rosepine = require("rose-pine")

  rosepine.setup({
    dark_variant = 'main',
  })

  -- vim.o.background = "light"

  require("utils").set_theme({ theme = "rose-pine" })
end

M.oxocarbon = function()
  require("utils").set_theme({ theme = "oxocarbon" })
end

M.github = function()
  require("github-theme").setup({
    theme_style = "dimmed",
    -- other config
  })
  -- require("utils").set_theme({ theme = "github_dimmed" });
end

M.nord = function()
  require("utils").set_theme({ theme = "nord" });
end

return M
