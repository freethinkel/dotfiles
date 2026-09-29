return {
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-lspconfig",
      "mfussenegger/nvim-dap",
    },
    keys = {
      -- flutter-tools' own menu is telescope-only; snacks lists its :Flutter* commands instead
      {
        "<leader>FF",
        function()
          Snacks.picker.commands({ pattern = "Flutter" })
        end,
        desc = "Flutter commands",
      },
      { "<leader>Fe", "<cmd>FlutterEmulators<cr>", desc = "FlutterEmulators" },
      { "<leader>Fr", "<cmd>FlutterRun<cr>", desc = "FlutterRun" },
      { "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "FlutterQuit" },
      { "<leader>FR", "<cmd>FlutterRestart<cr>", desc = "FlutterRestart" },
      { "<leader>FC", "<cmd>FlutterLogClear<cr>", desc = "FlutterLogClear" },
    },
    config = function()
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
    end,
  },
}
