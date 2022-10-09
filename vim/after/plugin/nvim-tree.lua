local config = {
    git = {
        enable = true,
        ignore = false,
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
            hint = "", info = "",
            warning = "",
            error = "",
        },
    },
    filters = {
        dotfiles = false,
    },
    filesystem_watchers = {
        enable = true,
    },
    actions = {
        open_file = {
            resize_window = true,
        },
    },
    update_focused_file = {
        enable = true,
        update_cwd = false,
    },
    update_cwd = true,
    renderer = {
        highlight_git = true,
        highlight_opened_files = "none",
        indent_markers = {
            enable = true,
            icons = {
                corner = "└",
                edge = "│",
                none = " ",
            },
        },
        icons = {
            webdev_colors = true,
            git_placement = "signcolumn",
            padding = " ",
            symlink_arrow = " 壟 ",
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
        },
    },
};


local status, nvimtree = pcall(require, 'nvim-tree');
if (not status) then
  return
end

nvimtree.setup(config)

local keymap = require('config.utils').set_keymap
keymap('n', '<leader>e', ':NvimTreeFocus<CR>')

