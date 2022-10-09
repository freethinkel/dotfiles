local status, null_ls = pcall(require, 'null-ls')

if (not status) then
  return
end

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

local augroup_format = vim.api.nvim_create_augroup("Format", { clear = true })

local b = null_ls.builtins;

null_ls.setup({
  sources = {
    --web
    null_ls.builtins.diagnostics.eslint,
    b.formatting.prettier.with({
      filetypes = prettier_format_filetypes,
    }),
    b.formatting.dart_format,
    --other
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.completion.spell,
  },
  on_attach = function(client)
    if client.server_capabilities.documentFormattingProvider then
      vim.api.nvim_clear_autocmds { buffer = 0, group = augroup_format }
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup_format,
        buffer = 0,
        callback = function() vim.lsp.buf.formatting_seq_sync() end
      })
    end
  end,
})
