require("bufferline").setup({
  options = {
    mode = "buffers",                        -- set to "tabs" to only show tabpages instead
    right_mouse_command = "vert sbuffer %d", -- can be a string | function, see "Mouse actions"
    max_name_length = 18,
    max_prefix_length = 15,                  -- prefix used when a buffer is de-duplicated
    truncate_names = true,                   -- whether or not tab names should be truncated
    tab_size = 18,
    hover = {
      enabled = true,
      delay = 200,
      reveal = { 'close' }
    },
    offsets = {
      {
        filetype = "undotree",
        text = "Undotree",
        highlight = "PanelHeading",
        padding = 1,
      },
      {
        filetype = "NvimTree",
        text = "Explorer",
        highlight = "PanelHeading",
        padding = 1,
      },
      {
        filetype = "neo-tree",
        text = "Explorer",
        highlight = "PanelHeading",
        padding = 1,
      },
      {
        filetype = "DiffviewFiles",
        text = "Diff View",
        highlight = "PanelHeading",
        padding = 1,
      },
      {
        filetype = "flutterToolsOutline",
        text = "Flutter Outline",
        highlight = "PanelHeading",
      },
      {
        filetype = "lazy",
        text = "Lazy",
        highlight = "PanelHeading",
        padding = 1,
      },
    },
  }
})


require("core.utils").load_mappings("bufferline")
