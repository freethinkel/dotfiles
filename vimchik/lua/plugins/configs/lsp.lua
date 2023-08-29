local M = {}

M.on_attach = function(client)
  require("core.utils").load_mappings("lsp")
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    command = [[nnoremap <buffer> <CR> <CR>:cclose<CR>]]
  })
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

local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities.textDocument.completion.completionItem = {
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


M.setup_server = function(server, opts)
  local default_server_options = {
    on_attach = M.on_attach,
    capabilities = capabilities,
  }
  local lspconfig = require("lspconfig")
  lspconfig[server].setup(require("core.utils").merge_tb(default_server_options, opts or {}))
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
end

M.setup_servers = function()
  M.setup_server("tsserver")
  M.setup_server("lua_ls", {
    settings = {
      Lua = {
        telemetry = { enable = false },
        runtime = {
          version = "LuaJIT",
          special = {
            reload = "require",
          },
        },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          library = {
            "${3rd}/busted/library",
            "${3rd}/luassert/library",
            "${3rd}/luv/library",
            vim.fn.expand "$VIMRUNTIME/lua",
            vim.fn.expand "$VIMRUNTIME/lua/vim/lsp",
            vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
            vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
            require("neodev.config").types(),
          },

          maxPreload = 5000,
          preloadFileSize = 10000,
        },
      },
    }
  })
  M.setup_server("stylelint_lsp", {
    filetypes = { "css", "scss", "sass", "pcss", "postcss" }
  })
  M.setup_server("cssmodules_ls")

  M.setup_server("cssls")
  M.setup_server("eslint")
  M.setup_server("angularls")
  M.setup_server("emmet_ls")
  M.setup_server("rust_analyzer")
end

M.null_ls = function()
  local b = require("null-ls").builtins;
  require("null-ls").setup({
    sources = {
      b.formatting.prettier,
    }
  })
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
      on_attach = M.on_attach,
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
  require("telescope").load_extension("flutter")
end

return M
