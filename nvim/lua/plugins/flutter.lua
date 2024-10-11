return {
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
      "nvim-lspconfig",
      "mfussenegger/nvim-dap",
    },
    keys = {

      {
        "<leader>FF",
        function()
          require("telescope").extensions.flutter.commands()
        end,
        "Flutter commands",
      },
      { "<leader>Fe", ":FlutterEmulators<cr>", "FlutterEmulators" },
      { "<leader>Fr", ":FlutterRun<cr>", "FlutterRun" },
      { "<leader>Fq", ":FlutterQuit<cr>", "FlutterQuit" },
      { "<leader>FR", ":FlutterRestart<cr>", "FlutterRestart" },
      { "<leader>FC", ":FlutterLogClear<cr>", "FlutterLogClear" },
    },
    config = function()
      -- local configs = require "nvchad.configs.lspconfig"

      require("flutter-tools").setup({
        lsp = {
          -- on_attach = configs.on_attach,
          color = {
            enabled = true,
            background = true,
            -- foreground = true,
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
    end,
  },
}
