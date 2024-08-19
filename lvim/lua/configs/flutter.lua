return {
  "akinsho/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim", -- optional for vim.ui.select
    "nvim-lspconfig",
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
    { "<leader>Fr", ":FlutterRun<cr>",       "FlutterRun" },
    { "<leader>Fq", ":FlutterQuit<cr>",      "FlutterQuit" },
    { "<leader>FR", ":FlutterRestart<cr>",   "FlutterRestart" },
    { "<leader>FC", ":FlutterLogClear<cr>",  "FlutterLogClear" },
  },
  config = function()
    require('flutter-tools').setup({
      fvm = true, -- takes priority over path, uses <workspace>/.fvm/flutter_sdk if enabled
      widget_guides = {
        enabled = false,
      },
      ui = {
        border = "rounded",
        notification_style = "plugin",
      },
      decorations = {
        statusline = {
          app_version = true,
          device = true,
          project_config = true
        },
      },
      debugger = {          -- integrate with nvim dap + install dart code debugger
        enabled = true,
        run_via_dap = true, -- use dap instead of a plenary job to run flutter apps
        exception_breakpoints = {},
        register_configurations = function(_)
          require("dap").configurations.dart = {}
          require("dap.ext.vscode").load_launchjs()
        end,
      },
      lsp = {

        color = { -- show the derived colours for dart variables
          enabled = true, -- whether or not to highlight color variables at all, only supported on flutter >= 2.10
          background = true, -- highlight the background
          foreground = false, -- highlight the foreground
          virtual_text = true, -- show the highlight using virtual text
          virtual_text_str = "■", -- the virtual text character to highlight
        },
        settings = {
          showTodos = true,
          completeFunctionCalls = true,
          renameFilesWithClasses = "prompt", -- "always"
          enableSnippets = true,
          enableSdkFormatter = true,
        },
      },
    })
  end,
}
