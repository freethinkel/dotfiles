return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        oxlint = {},
      },
      setup = {
        oxlint = function()
          -- oxlint's lspconfig on_attach exposes :LspOxlintFixAll; run it on save.
          -- Note the callback takes (buf, client), the reverse of the old
          -- LazyVim.lsp.on_attach signature this replaced.
          Snacks.util.lsp.on({ name = "oxlint" }, function(buf)
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = buf,
              command = "LspOxlintFixAll",
            })
          end)
        end,
      },
    },
  },
}
