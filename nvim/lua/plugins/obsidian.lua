return {
  {
    "obsidian-nvim/obsidian.nvim",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: new note" },
      { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Obsidian: open in app" },
      { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: search" },
      { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: quick switch" },
      { "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Obsidian: today" },
      { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Obsidian: yesterday" },
      { "<leader>ot", "<cmd>ObsidianTomorrow<cr>", desc = "Obsidian: tomorrow" },
      { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian: backlinks" },
      { "<leader>oT", "<cmd>ObsidianTags<cr>", desc = "Obsidian: tags" },
      { "<leader>ol", "<cmd>ObsidianLink<cr>", desc = "Obsidian: link selection", mode = "v" },
      { "<leader>oL", "<cmd>ObsidianLinkNew<cr>", desc = "Obsidian: link new", mode = "v" },
      { "<leader>op", "<cmd>ObsidianPasteImg<cr>", desc = "Obsidian: paste image" },
    },
    opts = {
      workspaces = {
        {
          name = "notes",
          path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes",
        },
      },
      notes_subdir = "notes",
      new_notes_location = "notes_subdir",
      daily_notes = {
        folder = "60 Daily",
        date_format = "%Y-%m-%d",
        template = nil,
      },
      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },
      completion = {
        nvim_cmp = false,
        blink = true,
        min_chars = 2,
      },
      picker = {
        name = "snacks.pick",
      },
      ui = { enable = true },
      attachments = {
        img_folder = "assets",
      },
      follow_url_func = function(url)
        vim.ui.open(url)
      end,
    },
  },
}
