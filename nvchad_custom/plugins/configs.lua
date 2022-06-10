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
  },
  diagnostics = {
    enable = true,
    show_on_dirs = false,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  filters = {
    dotfiles = false
  },
  renderer = {
    highlight_git = true,
    highlight_opened_files = "none",
    indent_markers = {
      enable = false,
      icons = {
        corner = "└ ",
        edge = "│ ",
        none = "  ",
      },
    },
    icons = {
      git_placement = "after",
      show = {
        git = false,
        folder_arrow = true
      },
     glyphs = {
      default = "",
      symlink = "",
      folder = {
       default = "",
       empty = "",
       empty_open = "",
       open = "",
       symlink = "",
       symlink_open = "",
       arrow_open = "",
       arrow_closed = "",
      },
      git = {
       unstaged = "",
       staged = "✓",
       unmerged = "",
       renamed = "➜",
       untracked = "★",
       deleted = "",
       ignored = "",
      },
     },
    }
  }
}

return M
