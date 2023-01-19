local M = {}

M.flutter = function()
  local status, flutter = pcall(require, "flutter-tools")
  if not status then
    return
  end

  flutter.setup()
end

M.lspsaga = function()
  local status, lspsaga = pcall(require, "lspsaga")
  if not status then
    return
  end

  lspsaga.setup({
    code_action_icon = "",
  })
end

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

M.null_ls = function()
  local status, null_ls = pcall(require, "null-ls")
  if not status then
    return
  end
  local b = null_ls.builtins

  local prettier_format_filetypes = {
    "html",
    "markdown",
    "css",
    "typescript",
    "javascript",
    "typescriptreact",
    "javascriptreact",
    "svelte",
    "postcss",
    "json",
  }

  local sources = {
    b.formatting.prettier.with({
      filetypes = prettier_format_filetypes,
    }),
    b.formatting.rustfmt,
    b.formatting.dart_format,
    -- Prisma
    b.formatting.prismaFmt,
    -- Lua
    b.formatting.stylua,
    b.diagnostics.luacheck.with({ extra_args = { "--global vim" } }),

    -- Shell
    b.formatting.shfmt,
    -- b.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),
  }
  null_ls.setup({
    sources = sources,
    on_attach = M.on_attach,
  })
end

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

  local function lspSymbol(name, icon)
    local hl = "DiagnosticSign" .. name
    vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
  end

  lspSymbol("Error", "")
  lspSymbol("Info", "")
  lspSymbol("Hint", "")
  lspSymbol("Warn", "")

  mason_lspconfig.setup({
    ensure_installed = { "sumneko_lua", "rust_analyzer" },
  })

  local servers = mason_lspconfig.get_installed_servers()

  for _, server in pairs(servers) do
    M.setup_server(server, {})
  end
end

return M
