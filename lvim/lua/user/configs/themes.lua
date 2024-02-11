local M = {}

M.themes = {
  tokyonight = function()
    lvim.colorscheme                            = "tokyonight"
    lvim.builtin.theme.name                     = "tokyonight"
    lvim.builtin.theme.tokyonight.options.style = "night"
    -- lvim.builtin.theme.tokyonight.options.transparent = true
  end,
  catppuccin = function()
    lvim.colorscheme = "catppuccin-frappe"
    lvim.builtin.theme.catppuccin.options.style = "mocca"
  end,
  github = function()
    lvim.colorscheme = "github_dimmed"
  end,
  gruvbox_material = function()
    lvim.colorscheme = "gruvbox-material"
    vim.o.background = "dark"
  end,
  oxocarbon = function()
    lvim.colorscheme = "oxocarbon";
  end,
  mountain = function()
    lvim.colorscheme = "mountain"
  end,
  nord = function()
    lvim.colorscheme = "nord"
    lvim.transparent_window = true
  end,
  monochrome = function()
    lvim.colorscheme = "base16-grayscale-dark"
  end,
  rose_pine = function()
    lvim.colorscheme = "rose-pine"
  end,
  rose_pine_moon = function()
    lvim.colorscheme = "rose-pine-moon"
  end,
  pomandres = function()
    lvim.colorscheme = "poimandres"
  end,
  oshmes = function()
    lvim.colorscheme = "oshmes-dark"
    -- lvim.transparent_window = true
  end,
  monokai_pro = function()
    M.monokai_pro()
    lvim.colorscheme = "monokai-pro-default"
  end,
  vesper = function()
    lvim.colorscheme = "vesper"
  end
}

M.set_theme = function(theme)
  pcall(theme)
end

M.monokai_pro = function()
  require("monokai-pro").setup({
    transparent_background = false,
    terminal_colors = true,
    devicons = true, -- highlight the icons of `nvim-web-devicons`
    styles = {
      comment = { italic = true },
      keyword = { italic = true },       -- any other keyword
      type = { italic = true },          -- (preferred) int, long, char, etc
      storageclass = { italic = true },  -- static, register, volatile, etc
      structure = { italic = true },     -- struct, union, enum, etc
      parameter = { italic = true },     -- parameter pass in function
      annotation = { italic = true },
      tag_attribute = { italic = true }, -- attribute of tag in reactjs
    },
    filter = "pro",                      -- classic | octagon | pro | machine | ristretto | spectrum
    -- Enable this will disable filter option
    day_night = {
      enable = false,            -- turn off by default
      day_filter = "ristretto",  -- classic | octagon | pro | machine | ristretto | spectrum
      night_filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
    },
    inc_search = "background",   -- underline | background
    background_clear = {
      -- "float_win",
      "toggleterm",
      "telescope",
      "which-key",
      "renamer"
    }, -- "float_win", "toggleterm", "telescope", "which-key", "renamer", "neo-tree"
    plugins = {
      bufferline = {
        underline_selected = false,
        underline_visible = false,
      },
      indent_blankline = {
        context_highlight = "default", -- default | pro
        context_start_underline = false,
      },
    },
  })
end

M.github = function()
  require("github-theme").setup({
    theme_style = "dimmed",
  })
end

return M
