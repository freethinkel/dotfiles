local utils = require("core.utils")

utils.load_mappings(nil, require("core.mappings"))
utils.setup_plugins(require("plugins"))

utils.load_highlights(require("core.highlights").setup())

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  pattern = { "*" },
  callback = function()
    utils.load_highlights(require("core.highlights").setup())
  end,
})

utils.set_theme("oshmes-dark")

require("core.options")
require("core.ui")
