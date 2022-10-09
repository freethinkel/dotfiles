require("core.options")
require("core.utils").load_mappings(require("core.mappings").mappings)

local theme = require("core.utils").load_config().ui.theme

local set_theme = function(theme) 
  pcall(vim.cmd, "colorscheme " .. theme)
end

set_theme(theme)


