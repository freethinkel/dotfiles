local M = {}

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

M.setup = function()
  local status, null_ls = pcall(require, "null-ls")
  if not status then
    return
  end

  local b = null_ls.builtins

  null_ls.setup({
    on_attach = require("plugins.config.lspconfig").on_attach,
    sources = {
      b.completion.spell,

      b.formatting.prettier.with({
        filetypes = prettier_format_filetypes,
      }),
      b.formatting.dart_format,
      b.code_actions.gitsigns,
      b.code_actions.eslint,
      b.diagnostics.eslint,
      -- Prisma
      b.formatting.prismaFmt,
      -- Lua
      b.formatting.stylua,
      b.diagnostics.luacheck.with({ extra_args = { "--global vim" } }),
      -- Shell
      b.formatting.shfmt,
    },
  })
end

return M
