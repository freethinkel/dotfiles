return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        stylelint_lsp = {
          filetypes = { "css", "scss", "less", "sass", "pcss", "vue", "svelte" },
        },
        svelte = {
          on_attach = function(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePost", {
              pattern = { "*.js", "*.ts" },
              callback = function(ctx)
                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
              end,
            })
          end,
        },
      },
    },
  },
  {
    "OlegGulevskyy/better-ts-errors.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = {
      keymaps = {
        toggle = "<leader>dd", -- default '<leader>dd'
        -- go_to_definition = "<leader>dx", -- default '<leader>dx'
      },
    },
  },
}
