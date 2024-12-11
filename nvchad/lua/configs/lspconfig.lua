-- EXAMPLE
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local map = vim.keymap.set

local on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
  map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
  map("n", "<leader>sh", vim.lsp.buf.signature_help, opts "Show signature help")
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")

  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  map("n", "<leader>rn", require "nvchad.lsp.renamer", opts "NvRenamer")

  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")
  map("n", "gr", ":Telescope lsp_references<cr>", opts "Show references")
end

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "eslint", "astro", "gopls", "prismals", "rust_analyzer", "jsonls", "emmet_ls" }

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

lspconfig.stylelint_lsp.setup {
  filetypes = { "css", "scss", "sass", "pcss", "postcss" },
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
}

lspconfig.vtsls.setup {
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
      print "ON MOVE FILE"
      ---@type string, string, lsp.Range
      local action, uri, range = unpack(command.arguments)

      local function move(newf)
        client.request("workspace/executeCommand", {
          command = command.command,
          arguments = { action, uri, range, newf },
        })
      end
      local fname = vim.uri_to_fname(uri)
      client.request("workspace/executeCommand", {
        command = "typescript.tsserverRequest",
        arguments = {
          "getMoveToRefactoringFileSuggestions",
          {
            file = fname,
            startLine = range.start.line + 1,
            startOffset = range.start.character + 1,
            endLine = range["end"].line + 1,
            endOffset = range["end"].character + 1,
          },
        },
      }, function(_, result)
        ---@type string[]
        local files = result.body.files
        table.insert(files, 1, "Enter new path...")
        vim.ui.select(files, {
          prompt = "Select move destination:",
          format_item = function(f)
            return vim.fn.fnamemodify(f, ":~:.")
          end,
        }, function(f)
          if f and f:find "^Enter new path" then
            vim.ui.input({
              prompt = "Enter move destination:",
              default = vim.fn.fnamemodify(fname, ":h") .. "/",
              completion = "file",
            }, function(newf)
              return newf and move(newf)
            end)
          elseif f then
            move(f)
          end
        end)
      end)
    end
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rf", "<cmd>lua require('vts').format()<cr>", { noremap = true, silent = true })
  end,
  on_init = on_init,
  capabilities = capabilities,
  single_file_support = false,
  root_dir = lspconfig.util.root_pattern "tsconfig.json",
}

lspconfig.denols.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}

lspconfig.svelte.setup {
  on_init = on_init,
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
  end,
}

lspconfig.lua_ls.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
          [vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types"] = true,
          [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
          ["${3rd}/luv/library"] = true,
        },
        maxPreload = 100000,
        preloadFileSize = 10000,
      },
    },
  },
}
