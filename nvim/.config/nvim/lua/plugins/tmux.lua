return {
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
    keys = {
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Go to the previous pane" },
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Got to the left pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Got to the down pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Got to the up pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Got to the right pane" },
    },
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
      -- vim-herdr-navigation ставится самим herdr, одинаково на всех машинах.
      -- Каталог с хешем в имени, поэтому glob; абсолютный путь к рабочей копии
      -- сюда прописывать нельзя — переезд проектов ломает навигацию молча.
      local candidates =
        vim.fn.glob(vim.fn.expand("~/.config/herdr/plugins/github/vim-herdr-navigation-*/editor/nvim.lua"), false, true)
      for _, path in ipairs(candidates) do
        if vim.uv.fs_stat(path) then
          dofile(path)
          return
        end
      end
      vim.notify("vim-herdr-navigation not found: Ctrl+hjkl won't cross into herdr panes", vim.log.levels.WARN)
    end,
  },
}
