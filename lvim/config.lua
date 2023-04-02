--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable ]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = true
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false
vim.opt.fillchars = vim.opt.fillchars + "diff:╱" + 'eob: '
-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
vim.opt.timeoutlen = 150

vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")

lvim.keys.insert_mode["jj"] = "<esc>"
lvim.keys.insert_mode["kj"] = "<esc>"
lvim.keys.insert_mode["Kj"] = "<esc>"
lvim.keys.insert_mode["jk"] = "<esc>"
lvim.keys.insert_mode["Jk"] = "<esc>"
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"

-- LSP MAPPING
-- lvim.keys.normal_mode["<leader>la"] = { "<cmd>Lspsaga code_action<cr>", "Code actions" }
lvim.builtin.which_key.mappings['l']['a'] = {
  "<cmd>Lspsaga code_action<cr>",
  "Code actions"
}
lvim.builtin.which_key.mappings['l']['r'] = {
  "<cmd>Lspsaga rename<cr>",
  "Rename"
}
lvim.builtin.which_key.mappings['l']['c'] = {
  "<cmd>Lspsaga show_cursor_diagnostics<cr>",
  "Show cursor diagnostic"
}
lvim.builtin.which_key.mappings['l']['j'] = {
  "<cmd>Lspsaga diagnostic_jump_next<cr>",
  "Show cursor diagnostic"
}
lvim.builtin.which_key.mappings['l']['k'] = {
  "<cmd>Lspsaga diagnostic_jump_prev<cr>",
  "Show cursor diagnostic"
}
lvim.lsp.buffer_mappings.normal_mode['gd'] = { "<cmd>Lspsaga goto_definition<cr>", "Goto definitions" }
lvim.lsp.buffer_mappings.normal_mode['gp'] = { "<cmd>Lspsaga peek_definition<cr>", "Peek definitions" }
lvim.lsp.buffer_mappings.normal_mode['gr'] = { "<cmd>Lspsaga lsp_finder<cr>", "Goto references" }
lvim.lsp.buffer_mappings.normal_mode['K'] = { "<cmd>Lspsaga hover_doc<cr>", "Show hover" }

lvim.builtin.which_key.mappings["F"] = {
  name = "Flutter",
  r = { ":FlutterRun<cr>", "FlutterRun" },
  q = { ":FlutterQuit<cr>", "FlutterQuit" },
  R = { ":FlutterRestart<cr>", "FlutterRestart" },
  C = { ":FlutterLogClear<cr>", "FlutterLogClear" }
  -- "<cmd>Lspsaga diagnostic_jump_prev<cr>",
  -- "Show cursor diagnostic"
}

-- ["K"] = { "<cmd>lua vim.lsp.buf.hover()<cr>", "Show hover" },
-- ["gd"] = { "<cmd>lua vim.lsp.buf.definition()<cr>", "Goto Definition" },
-- ["gD"] = { "<cmd>lua vim.lsp.buf.declaration()<cr>", "Goto declaration" },
-- ["gr"] = { "<cmd>lua vim.lsp.buf.references()<cr>", "Goto references" },
-- ["gI"] = { "<cmd>lua vim.lsp.buf.implementation()<cr>", "Goto Implementation" },
-- ["gs"] = { "<cmd>lua vim.lsp.buf.signature_help()<cr>", "show signature help" },
-- ["gl"] = {
--   function()
--     local config = lvim.lsp.diagnostics.float
--     config.scope = "line"
--     vim.diagnostic.open_float(0, config)
--   end,
--   "Show line diagnostics",
-- },
-- LSP MAPPING END

-- unmap a default keymapping
-- vim.keymap.del("n", "<C-Up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

-- hange Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
-- local _, actions = pcall(require, "telescope.actions")
-- lvim.builtin.telescope.defaults.mappings = {
--   -- for input mode
--   i = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--     ["<C-n>"] = actions.cycle_history_next,
--     ["<C-p>"] = actions.cycle_history_prev,
--   },
--   -- for normal mode
--   n = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--   },
-- }

-- Change theme settings
-- lvim.colorscheme = "github_dimmed"
--
-- lvim.colorscheme                            = "tokyonight"
-- lvim.builtin.theme.name                     = "tokyonight"
-- lvim.builtin.theme.tokyonight.options.style = "night"
-- lvim.builtin.theme.tokyonight.options.transparent = true
--
lvim.colorscheme = "catppuccin-frappe"
-- lvim.builtin.theme.catppuccin.options.style = "mocca"

-- LUALINE
local lualine_components = require "lvim.core.lualine.components"
lvim.builtin.lualine.style = "lvim"
lvim.builtin.lualine.sections.lualine_a = {
  {
    function()
      return " " .. vim.api.nvim_get_mode()['mode']:upper() .. " "
    end,
    padding = { left = 0, right = 0 },
    color = {},
    cond = nil,
  },
}
lvim.builtin.lualine.sections.lualine_x = {
  lualine_components.diagnostics
}
lvim.builtin.lualine.sections.lualine_y = {
  "searchcount",
  "encoding",
  {
    "filetype",
    colored = false,
  },
  {
    "progress",
    separator = { left = "" },
  },
}
lvim.builtin.lualine.sections.lualine_z = {
  {
    "location",
    padding = { left = 0, right = 1 },
  },
}

-- lvim.builtin.theme.options.dim_inactive = true
-- lvim.builtin.theme.options.style = "night"

-- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
-- lvim.builtin.which_key.mappings["t"] = {
--   name = "+Trouble",
--   r = { "<cmd>Trouble lsp_references<cr>", "References" },
--   f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
--   d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
--   q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
--   l = { "<cmd>Trouble loclist<cr>", "LocationList" },
--   w = { "<cmd>Trouble workspace_diagnostics<cr>", "Workspace Diagnostics" },
-- }

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.gitsigns.opts.current_line_blame = true
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"

lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

lvim.builtin.gitsigns.opts.signs.untracked = {
  text = "┃",
  hl = "GitSignsAdd",
  numhl = "GitSignsAddNr",
  linehl = "GitSignsAddLn"
};


-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.auto_install = true
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true

-- generic LSP settings

-- -- make sure server will always be installed even if the server is in skipped_servers list
lvim.lsp.installer.setup.ensure_installed = {
  "sumneko_lua",
  "tsserver",
  "eslint",
  "jsonls",
}
-- -- change UI setting of `LspInstallInfo`
-- -- see <https://github.com/williamboman/nvim-lsp-installer#default-configuration>
-- lvim.lsp.installer.setup.ui.check_outdated_servers_on_open = false
-- lvim.lsp.installer.setup.ui.border = "rounded"
-- lvim.lsp.installer.setup.ui.keymaps = {
--     uninstall_server = "d",
--     toggle_server_expand = "o",
-- }

-- ---@usage disable automatic installation of servers
-- lvim.lsp.installer.setup.automatic_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "black", filetypes = { "python" } },
  { command = "isort", filetypes = { "python" } },
  {
    -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
    command = "prettier",
    ---@usage arguments to pass to the formatter
    -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
    extra_args = { "--print-with", "100" },
    ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
    filetypes = { "typescript", "typescriptreact", "html", "css", "postcss", "javascript", "javascriptreact" },
  },
}

-- lvim.lsp.override = { "dart" }
require("lvim.lsp.manager").setup("lua_ls")
require("lvim.lsp.manager").setup("cssmodules_ls")
require("lvim.lsp.manager").setup("eslint")
require("lvim.lsp.manager").setup("angularls")
require("lvim.lsp.manager").setup("emmet_ls")

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"

-- linters.setup {
--   { command = "flake8", filetypes = { "python" } },
--   {
--     -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "shellcheck",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--severity", "warning" },
--   },
--   {
--     command = "codespell",
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "javascript", "python" },
--   },
-- }
--

-- Additional Plugins
lvim.plugins = {
  { "mg979/vim-visual-multi" },
  { "christoomey/vim-tmux-navigator" },
  {
    "akinsho/flutter-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("flutter-tools").setup({
        lsp = {
          on_attach = require("lvim.lsp").common_on_attach
        },
        debugger = {
          -- integrate with nvim dap + install dart code debugger
          enabled = true,
          exception_breakpoints = {},
          register_configurations = function(_)
            require("dap").configurations.dart = {}
            require("dap.ext.vscode").load_launchjs()
          end,
        }
      })
    end
  },
  { "imsnif/kdl.vim" },
  { "rescript-lang/vim-rescript" },
  {
    "sindrets/diffview.nvim",
    event = "BufRead",
  },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  {
    "glepnir/lspsaga.nvim",
    branch = "main",
    config = function()
      require("lspsaga").setup({
        ui = {
          -- currently only round theme
          theme = "round",
          -- this option only work in neovim 0.9
          title = true,
          -- border type can be single,double,rounded,solid,shadow.
          border = "rounded",
          winblend = 0,
          expand = "",
          collapse = "",
          preview = " ",
          code_action = "",
          incoming = " ",
          outgoing = " ",
          kind = {},
        },
      })
    end,
  },
  { 'nyoom-engineering/oxocarbon.nvim' },
  { "catppuccin/nvim",                 name = "catppuccin" },
  { "stephenway/postcss.vim" },
  {
    "loctvl842/monokai-pro.nvim",
    config = function()
      -- require("monokai-pro").setup({
      --   transparent_background = false,
      --   terminal_colors = true,
      --   devicons = true, -- highlight the icons of `nvim-web-devicons`
      --   styles = {
      --     comment = { italic = true },
      --     keyword = { italic = true },       -- any other keyword
      --     type = { italic = true },          -- (preferred) int, long, char, etc
      --     storageclass = { italic = true },  -- static, register, volatile, etc
      --     structure = { italic = true },     -- struct, union, enum, etc
      --     parameter = { italic = true },     -- parameter pass in function
      --     annotation = { italic = true },
      --     tag_attribute = { italic = true }, -- attribute of tag in reactjs
      --   },
      --   filter = "pro",                      -- classic | octagon | pro | machine | ristretto | spectrum
      --   -- Enable this will disable filter option
      --   day_night = {
      --     enable = false,            -- turn off by default
      --     day_filter = "ristretto",  -- classic | octagon | pro | machine | ristretto | spectrum
      --     night_filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
      --   },
      --   inc_search = "background",   -- underline | background
      --   background_clear = {
      --     -- "float_win",
      --     "toggleterm",
      --     "telescope",
      --     "which-key",
      --     "renamer"
      --   }, -- "float_win", "toggleterm", "telescope", "which-key", "renamer", "neo-tree"
      --   plugins = {
      --     bufferline = {
      --       underline_selected = false,
      --       underline_visible = false,
      --     },
      --     indent_blankline = {
      --       context_highlight = "default", -- default | pro
      --       context_start_underline = false,
      --     },
      --   },
      -- })
    end
  },
  {
    "projekt0n/github-nvim-theme",
    version = 'v0.0.7',
    config = function()
      require('github-theme').setup({
        theme_style = "dimmed"
      })
    end
  }
  -- {
  --   "folke/trouble.nvim",
  --   cmd = "TroubleToggle",
  -- },
  -- { "aserowy/tmux.nvim", config = function() require("tmux").setup() end }
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = { "*.json", "*.jsonc" },
--   -- enable wrap mode for json files only
--   command = "setlocal wrap",
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
