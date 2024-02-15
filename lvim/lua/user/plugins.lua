lvim.plugins = {
  { 'mg979/vim-visual-multi' },
  { 'christoomey/vim-tmux-navigator', lazy = false },
  { 'sainnhe/gruvbox-material' },
  { 'rktjmp/lush.nvim' },
  {
    'akinsho/flutter-tools.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'stevearc/dressing.nvim',
    },
    config = function()
      require('user.configs.lsp').flutter()
    end,
  },
  { 'imsnif/kdl.vim' },
  {
    'windwp/nvim-ts-autotag',
    config = function()
      require('nvim-ts-autotag').setup()
    end,
  },
  {
    'glepnir/lspsaga.nvim',
    branch = 'main',
    config = function()
      require('user.configs.lsp').lspsaga()
    end,
  },
  { 'nyoom-engineering/oxocarbon.nvim' },
  { 'catppuccin/nvim', name = 'catppuccin' },
  { 'stephenway/postcss.vim' },
  {
    'loctvl842/monokai-pro.nvim',
    config = function()
      require('user.configs.themes').monokai_pro()
    end,
  },
  {
    'projekt0n/github-nvim-theme',
    version = 'v0.0.7',
    config = function()
      require('user.configs.themes').github()
    end,
  },
  {
    'mountain-theme/vim',
    lazy = false,
  },
  { 'datsfilipe/vesper.nvim' },
  -- OWN THEME
  {
    dir = '~/Developer/dev/pet/oshmes.nvim/',
  },
  -- {
  --   "freethinkel/oshmes.nvim"
  -- },
  { 'shaunsingh/nord.nvim' },
  { 'rose-pine/neovim', name = 'rose-pine' },
  { 'olivercederborg/poimandres.nvim' },
  {
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = { 'BufReadPre' },
    config = function()
      require('user.configs.todo-comments').setup()
    end,
  },
  { 'nvim-treesitter/playground' },
  {
    'phaazon/hop.nvim',
    config = function()
      require('user.configs.hop').setup()
    end,
  },
  {
    'nvim-pack/nvim-spectre',
    config = function()
      require('user.configs.spectre').setup()
    end,
  },
  {
    'NvChad/nvim-colorizer.lua',
    lazy = false,
    config = function()
      require('colorizer').setup()
    end,
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen' },
    config = function()
      require('diffview').setup({
        enhanced_diff_hl = true,
        -- enhanced_diff_hl = false,
        hooks = {
          ---@param view StandardView
          view_opened = function(view)
            -- Highlight 'DiffChange' as 'DiffDelete' on the left, and 'DiffAdd' on
            -- the right.
            local function post_layout()
              -- utils.tbl_ensure(view, 'winopts.diff2.a')
              -- utils.tbl_ensure(view, 'winopts.diff2.b')
              view.winopts.diff2.a = utils.tbl_union_extend(view.winopts.diff2.a, {
                winhl = {
                  'DiffChange:DiffAddAsDelete',
                  'DiffText:DiffDeleteText',
                },
              })
              view.winopts.diff2.b = utils.tbl_union_extend(view.winopts.diff2.b, {
                winhl = {
                  'DiffChange:DiffAdd',
                  'DiffText:DiffAddText',
                },
              })
            end

            view.emitter:on('post_layout', post_layout)
            post_layout()
          end,
        },
      })
    end,
  },
}

require('user.configs.dap_ui')
