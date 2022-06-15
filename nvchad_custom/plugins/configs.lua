local M = {}

M.nvimtree = {
  git = {
    enable = true,
    ignore = false
  },
   view = {
    side = "left",
    width = 30,
    hide_root_folder = true,
    signcolumn = "yes",
  },
  diagnostics = {
    enable = false,
    show_on_dirs = false,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  filters = {
    dotfiles = false
  },
  renderer = {
    highlight_git = true,
    highlight_opened_files = "none",
    indent_markers = {
      enable = true,
      icons = {
        corner = "└ ",
        edge = "│ ",
        none = "  ",
      },
    },
    icons = {
      webdev_colors = true,
      git_placement = "signcolumn",
      padding = " ",
      symlink_arrow = " ➛ ",
      show = {
        file = true,
        folder = true,
        folder_arrow = false,
        git = false,
      },
     glyphs = {
      default = "",
      symlink = "",
      folder = {
       arrow_open = "",
       arrow_closed = "",
        default = "",
        open = "",
        empty = "",
        empty_open = "",
        symlink = "",
        symlink_open = "",
      },
      git = {
        unstaged = "",
        staged = "ﰶ",
        unmerged = "",
        renamed = "➜",
        untracked = "●",
        deleted = "﯀",
        ignored = "",
      },
     },
    }
  }
}

M.bufferline = {
  highlights = {
    background = {
     guibg = "NONE",
    },
    fill = {
     guibg = "NONE",
    },
    close_button = {
     guibg = "NONE",
    },
    separator_visible = {
     guibg = "NONE",
    },
    tab_close = {
     guibg = "NONE",
    },
  },
}

return M
