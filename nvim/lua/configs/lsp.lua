local M = {}

M.on_attach = function(client)
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      desc = "Auto format before save",
      pattern = "<buffer>",
      callback = function()
        vim.lsp.buf.format()
      end,
    })
  end
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

local default_server_options = {
  on_attach = M.on_attach,
  capabilities = M.capabilities,
}

M.setup_server = function(server, opts)
  local lspconfig = require("lspconfig")
  lspconfig[server].setup(require("utils").merge_tb(default_server_options, opts or {}))
end

M.setup = function()
  require("mason").setup()
  require("mason-lspconfig").setup({
    ensure_installed = {
      "lua_ls",
      "tsserver",
      "eslint",
      "jsonls",
      "emmet_ls",
    }
  })

  local servers = require("mason-lspconfig").get_installed_servers()

  for _, server in pairs(servers) do
    M.setup_server(server, {})
  end
end

M.null_ls = function()
  require("mason-null-ls").setup({
    automatic_setup = true,
  })
  require('mason-null-ls').setup_handlers()
end

M.lspsaga = function()
  require("lspsaga").setup({
    ui = {
      code_action = "",
      title = true,
      border = "single",
      winblend = 0,
      expand = "",
      collapse = "",
      incoming = " ",
      outgoing = " ",
      hover = ' ',
      kind = {},
    }
  })
end

M.flutter = function()
  require("flutter-tools").setup({
    lsp = {
      on_attach = M.on_attach
    },
    debugger = {
      enabled = true,
      exception_breakpoints = {},
      register_configurations = function(_)
        require("dap").configurations.dart = {}
        require("dap.ext.vscode").load_launchjs()
      end,
    }
  })
end

return M
