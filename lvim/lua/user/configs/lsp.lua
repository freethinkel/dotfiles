local M = {}

M.setup = function()
  lvim.lsp.installer.setup.ensure_installed = {
    "lua_ls",
    "tsserver",
    "eslint",
    "jsonls",
  }

  local formatters                          = require("lvim.lsp.null-ls.formatters")
  formatters.setup({
    { command = "black", filetypes = { "python" } },
    { command = "isort", filetypes = { "python" } },
    {
      command = "prettier",
      extra_args = { "--print-with", "100" },
      filetypes = { "typescript", "typescriptreact", "html", "css", "scss", "sass", "pcss", "postcss", "javascript",
        "javascriptreact" },
    },
  })

  require("lvim.lsp.manager").setup("lua_ls")
  require("lvim.lsp.manager").setup("stylelint_lsp", {
    filetypes = { "css", "scss", "sass", "pcss", "postcss" }
  })
  require("lvim.lsp.manager").setup("cssmodules_ls")
  require("lvim.lsp.manager").setup("cssls")
  require("lvim.lsp.manager").setup("eslint")
  require("lvim.lsp.manager").setup("angularls")
  require("lvim.lsp.manager").setup("emmet_ls")
  require("lvim.lsp.manager").setup("rust_analyzer")
  -- require("lvim.lsp.null-ls.linters").setup()
end

M.lspsaga = function()
  require("lspsaga").setup({
    ui = {
      theme = "round",
      title = true,
      border = "rounded",
      winblend = 0,
      expand = "",
      collapse = "",
      preview = " ",
      code_action = "",
      incoming = " ",
      outgoing = " ",
      kind = {},
    },
  })
end

M.flutter = function()
  require("telescope").load_extension("flutter")
  require("flutter-tools").setup({
    lsp = {
      on_attach = require("lvim.lsp").common_on_attach,
      color = {
        enabled = true,
        background = false,
        foreground = false,
        virtual_text = true,
        virtual_text_str = "■",
      },
    },
    debugger = {
      enabled = true,
      run_via_dap = true,
      exception_breakpoints = {},
      register_configurations = function(_)
        require("dap").configurations.dart = {}
        require("dap.ext.vscode").load_launchjs()
      end,
    },
    dev_log = {
      enabled = false,
    },
  })
end

return M
