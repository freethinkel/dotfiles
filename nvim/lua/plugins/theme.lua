local state = false

return {
  {
    dir = "~/Developer/dev/pet/nules.nvim",
  },
  {
    "shaunsingh/nord.nvim",
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },
  {
    "cdmill/neomodern.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      require("neomodern").setup({
        style = "campfire", -- choose between 'iceclimber', 'coffeecat', 'darkforest', 'campfire', 'roseprime', 'daylight'
      })
      require("neomodern").load()
    end,
  },
  {
    "jesseleite/nvim-noirbuddy",
    dependencies = {
      { "tjdevries/colorbuddy.nvim" },
    },
    lazy = true,
    priority = 1000,
    config = function()
      vim.schedule(function()
        local palette = {
          diagnostic_error = "#FA7583",
          diagnostic_hint = "#9BCAFF",
          diagnostic_info = "#9FECB7",
          diagnostic_warning = "#ffc799",
          diff_add = "#9FECB7",
          diff_change = "#ffc799",
          diff_delete = "#FA7583",
          blue = "#9BCAFF",
          yellow = "#ffc799",
          orange = "#ffc799",
          red = "#FA7583",
          primary = "#FFC803",
        }
        require("noirbuddy").setup({
          preset = "minimal",
          colors = palette,
          styles = {
            italic = true,
            bold = true,
            underline = true,
            undercurl = true,
          },
        })

        local colorbuddy = require("colorbuddy")
        local RGB = require("colorbuddy.data.rgb")

        local mix = function(_a, _b, amount)
          local a = RGB:from_hsl(_a:to_hsl())
          local b = RGB:from_hsl(_b:to_hsl())

          return RGB:new(
            a.r * (1 - amount) + b.r * amount,
            a.g * (1 - amount) + b.g * amount,
            a.b * (1 - amount) + b.b * amount
          ):to_vim()
        end

        local Color = colorbuddy.Color
        local colors = colorbuddy.colors
        local Group = colorbuddy.Group
        local groups = colorbuddy.groups
        local styles = colorbuddy.styles

        Color.new("blue", palette.blue)
        Color.new("yellow", palette.yellow)
        Color.new("orange", palette.orange)
        Color.new("red", palette.red)

        Color.new("diagnostic_hint_bg", mix(colors.diagnostic_hint, colors.background, 0.9))
        Color.new("diagnostic_info_bg", mix(colors.diagnostic_info, colors.background, 0.9))
        Color.new("diagnostic_error_bg", mix(colors.diagnostic_error, colors.background, 0.9))
        Color.new("diagnostic_warning_bg", mix(colors.diagnostic_warning, colors.background, 0.9))
        Color.new("primary_01", mix(colors.primary, colors.background, 0.9), nil, nil)

        Group.new("DiagnosticVirtualTextHint", colors.diagnostic_hint, colors.diagnostic_hint_bg, styles.undercurl)
        Group.new(
          "DiagnosticVirtualTextWarn",
          colors.diagnostic_warning,
          colors.diagnostic_warning_bg,
          styles.undercurl
        )
        Group.new(
          "DiagnosticUnderlineError",
          nil,
          colors.diagnostic_error_bg,
          styles.undercurl,
          colors.diagnostic_error,
          50
        )
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", {
          bg = colors.diagnostic_error_bg:to_vim(),
          underline = true,
          undercurl = true,
          sp = colors.diagnostic_error:to_vim(),
        })
        Group.new("DiagnosticVirtualTextError", colors.diagnostic_error, colors.diagnostic_error_bg, styles.undercurl)

        Group.new("DiagnosticVirtualTextInfo", colors.diagnostic_info, colors.diagnostic_info_bg, styles.undercurl)

        Group.new("VertSplit", groups.VertSplit, nil)
        Group.new("WinSeparator", groups.WinSeparator, nil)

        Group.new("NeoTreeGitUntracked", colors.diff_add)
        Group.new("NeoTreeGitUnstaged", colors.diff_change)
        Group.new("NeoTreeGitModified", colors.diff_change)

        Group.new("signifysigndelete", groups.signifysigndelete, nil, nil)
        Group.new("CursorLineNr", nil, nil, nil)

        Group.new("@ibl.scope.char.1", colors.primary_01, nil, nil)

        -- Icons
        Group.new("MiniIconsYellow", colors.yellow)
        Group.new("MiniIconsAzure", colors.blue)
        Group.new("MiniIconsCyan", colors.blue, nil, nil)
        Group.new("MiniIconsBlue", colors.blue, nil)
        Group.new("MiniIconsOrange", colors.orange, nil, nil)
        Group.new("MiniIconsRed", colors.red, nil, nil)
      end)
    end,
  },
  { "rebelot/kanagawa.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "noirbuddy",
      -- colorscheme = "kanagawa",
      -- colorscheme = "catppuccin",
      -- colorscheme = "rose-pine",
      -- colorscheme = "nules-dark",
      colorscheme = "jeju-dark",
    },
  },
}
