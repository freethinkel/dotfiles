local M = {}

M.on_attach = function(client, bufnr)
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      desc = "Auto format before save",
      pattern = "<buffer>",
      callback = function()
        vim.lsp.buf.format();
      end
    })
  end
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

local default_server_options = {
  on_attach = M.on_attach,
  capabilities = M.capabilities,
}



M.setup_server = function(server, opts)
  local lspconfig = require("lspconfig")
  lspconfig[server].setup(require("utils").merge_tb(default_server_options, opts or {}))
end

M.mason = function()
  local status, mason = pcall(require, "mason")
  if not status then
    return
  end

  mason.setup()
end

M.mason_lspconfig = function()
  local status, mason_lspconfig = pcall(require, "mason-lspconfig")
  if not status then
    return
  end

  mason_lspconfig.setup({
    ensure_installed = { "sumneko_lua", "rust_analyzer" },
  })

  local servers = mason_lspconfig.get_installed_servers();

  for _, server in pairs(servers) do
    M.setup_server(server, {})
  end
end


return M
