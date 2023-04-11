require("user.configs.themes").set_theme(require("user.configs.themes").themes.tokyonight)

require("user.options")
require("user.configs.lualine").setup()
require("user.configs.lsp").setup()
require("user.mappings")
require("user.plugins")
