vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
  -- Packer сам себя
  use 'wbthomason/packer.nvim'

  -----------------------------------------------------------
  -- ПЛАГИНЫ ВНЕШНЕГО ВИДА
  -----------------------------------------------------------

  -- Цветовая схема
  use 'joshdick/onedark.vim'
  use "catppuccin/nvim"

  --- Информационная строка внизу
  use { 
    'nvim-lualine/lualine.nvim',
    requires = {'kyazdani42/nvim-web-devicons', opt = true},
    config = function()
      require('lualine').setup()
    end, 
  }
  -- Табы вверху
  use {
    'akinsho/bufferline.nvim', requires = 'kyazdani42/nvim-web-devicons',
    config = function()
      require("bufferline").setup{}
    end, 
  }

  -----------------------------------------------------------
  -- НАВИГАЦИЯ
  -----------------------------------------------------------
  -- Файловый менеджер 
  use { 
    'kyazdani42/nvim-tree.lua',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function() require'nvim-tree'.setup {} end, 
  }

  use {
    "folke/which-key.nvim",
    config = function()
      require("core.which_key").setup()
    end
  }
  use 'majutsushi/tagbar'
  -- Замена fzf и ack
  use { 'nvim-telescope/telescope.nvim',
  requires = { {'nvim-lua/plenary.nvim'} },
  config = function() require'telescope'.setup {} end, }

  -----------------------------------------------------------
  -- LSP и автодополнялка
  -----------------------------------------------------------
  use 'nvim-treesitter/nvim-treesitter'
  use 'williamboman/nvim-lsp-installer'
  use "neovim/nvim-lspconfig"
  use "jose-elias-alvarez/null-ls.nvim"
  use "jose-elias-alvarez/nvim-lsp-ts-utils"

  -----------------------------------------------------------
  --  FRONTEND
  -----------------------------------------------------------
  use "evanleck/vim-svelte"

  -----------------------------------------------------------
  -- РАЗНОЕ
  -----------------------------------------------------------
  -- Даже если включена русская раскладка vim команды будут работать
  use 'powerman/vim-plugin-ruscmd'
  -- Стартовая страница, если просто набрать vim в консоле
  use 'mhinz/vim-startify'
  use {
    'numToStr/Comment.nvim',
    config = function() require('Comment').setup() end
  }
 --- popup окошки
  use 'nvim-lua/popup.nvim'

end)
