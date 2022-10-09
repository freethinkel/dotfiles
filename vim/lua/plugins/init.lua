local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
    vim.cmd([[packadd packer.nvim]])
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require("packer").startup(function(use)
  use("wbthomason/packer.nvim")
  use("kyazdani42/nvim-web-devicons")
  use("kyazdani42/nvim-tree.lua")
  use("nvim-treesitter/nvim-treesitter")
  use("nvim-lualine/lualine.nvim")
  use("windwp/nvim-autopairs")
  use("christoomey/vim-tmux-navigator")
  use("akinsho/bufferline.nvim")
  use("lewis6991/gitsigns.nvim")
  use({
    "nvim-telescope/telescope.nvim",
    requires = { { "nvim-lua/plenary.nvim" } },
  })

  -- LSP
  use("neovim/nvim-lspconfig")
  use("nvim-lua/plenary.nvim") -- Common utilities
  use("onsails/lspkind-nvim") -- vscode-like pictograms
  use("hrsh7th/cmp-buffer") -- nvim-cmp source for buffer words
  use("hrsh7th/cmp-nvim-lsp") -- nvim-cmp source for neovim's built-in LSP
  use("hrsh7th/nvim-cmp") -- Completion
  use("williamboman/mason.nvim")
  use("jose-elias-alvarez/null-ls.nvim") -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
  use("L3MON4D3/LuaSnip")

  -- THEMES
  use("projekt0n/github-nvim-theme")
  use("marko-cerovac/material.nvim")
  use("folke/tokyonight.nvim")
  use("bluz71/vim-moonfly-colors")
  use("JoosepAlviste/palenightfall.nvim")
  use({ "kartikp10/noctis.nvim", requires = { "rktjmp/lush.nvim" } })

  if packer_bootstrap then
    require("packer").sync()
  end
end)
