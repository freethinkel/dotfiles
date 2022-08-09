require "custom"

local M = {}
M.ui = {
  theme = "sweetpastel",
  theme_toggle = {"one_light", "tokyonight"},
  -- transparency = true
}

M.mappings = require "custom.mappings"

local pluginConfigs = require "custom.plugins.configs"

M.plugins = {
  user = require "custom.plugins",
  override = {
    ["kyazdani42/nvim-tree.lua"] = pluginConfigs.nvimtree,
    ["akinsho/bufferline.nvim"] = pluginConfigs.bufferline
  },
}

M.options = {
  user = function()
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.timeoutlen = 300
    vim.opt.swapfile = false
  end,
}

return M
