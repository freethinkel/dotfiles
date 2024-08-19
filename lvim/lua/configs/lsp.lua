lvim.lsp.installer.setup.ensure_installed = {
  "lua_ls",
  "eslint",
}

local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    name = "prettier",
  },
}

local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { name = "eslint" },
  {
    name = "shellcheck",
    args = { "--severity", "warning" },
  },
}
