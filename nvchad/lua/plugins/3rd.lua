return {
  {
    "vhyrro/luarocks.nvim",
    priority = 1001, -- this plugin needs to run before anything else
    opts = {
      rocks = { "magick" },
    },
  },
  {
    "3rd/image.nvim",
    lazy = false,
    dependencies = { "luarocks.nvim" },
    config = function()
      require("image").setup {
        backend = "kitty", -- or "ueberzug"
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 70,
        window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
        tmux_show_only_in_active_window = true,
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
      }
    end,
  },
}
