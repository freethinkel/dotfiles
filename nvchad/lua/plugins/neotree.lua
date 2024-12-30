return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    lazy = false,
    branch = "v3.x",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", "Toggle explorer" },
    },
    config = function()
      require("neo-tree").setup {
        sources = { "filesystem", "buffers", "git_status", "document_symbols" },
        open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
        filesystem = {
          bind_to_cwd = false,
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
        },
        buffers = {
          follow_current_file = {
            enabled = true, -- This will find and focus the file in the active buffer every time
            leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
          },
        },
        window = {
          mapping_options = {
            noremap = false,
          },
          mappings = {
            ["<space>"] = "none",
            ["l"] = "open",
            ["v"] = "open_vsplit",
            ["s"] = function(state)
              local node = state.tree:get_node()
              os.execute("open " .. node.path)
            end,
          },
        },
        enable_gi_status = true,
        enable_diagnostics = true,
        default_component_configs = {
          indent = {
            with_markers = true,
            indent_marker = "▏",
            last_indent_marker = "▏", -- │
            indent_size = 2,
            with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
            expander_collapsed = "",
            expander_expanded = "",
            expander_highlight = "NeoTreeExpander",
          },
          icon = {
            folder_closed = "󰉋",
            folder_open = "",
            folder_empty = "",
            default = "",
          },
          git_status = {
            symbols = {
              -- Change type
              added = "A",
              modified = "M",
              deleted = "D",
              renamed = "R",
              -- Status type
              ignored = "",
              untracked = "",
              unstaged = "",
              staged = "",
              conflict = "",
              --
              -- ignored = "I",
              -- untracked = "U",
              -- unstaged = "U",
              -- staged = "S",
              -- conflict = "C",
            },
          },
        },
      }
    end,
  },
}
