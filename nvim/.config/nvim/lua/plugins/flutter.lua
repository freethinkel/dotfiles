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

      -- ponytail: plugin-managed document colors are deprecated on nvim 0.12+; use the native API
      vim.lsp.document_color.enable()

      require("flutter-tools").setup({
        -- fvm=true uses the project's .fvm/flutter_sdk pin; flutter_path is the
        -- fallback to the global fvm default for unpinned projects (no flutter on PATH).
        -- ponytail: assumes `fvm global <ver>` is set; rerun it if ~/fvm/default breaks.
        fvm = true,
        flutter_path = vim.fn.expand("~/fvm/default/bin/flutter"),
        debugger = {
          enabled = true,
          run_via_dap = true,
          exception_breakpoints = {},
          -- register_configurations = function(_)
          --   require("dap").configurations.dart = {}
          --   require("dap.ext.vscode").load_launchjs()
          -- end,
        },
        dev_log = {
          enabled = false,
        },
      })
      -- require("fzf-lua").load_extension("flutter")
      -- require("telescope").load_extension("flutter")
    end,
  },
}
