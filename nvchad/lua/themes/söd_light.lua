---@type Base46Table
local M = {}

local Color = require "utils.color"

local theme = {
  schema = {
    base00 = "#FDFDFC",
    base01 = "#E5E5E5",
    base02 = "#E5E5E5",
    base03 = "#A0A0A0",
    base04 = "#5f5f5f",
    base05 = "#3C3C3C",
    base06 = "#E9E9E9",
    base07 = "#33a3ff",
    base08 = "#161616", -- just foreground
    base09 = "#161616",
    base0A = "#000000",
    base0B = "#A0A0A0",
    base0C = "#000000",
    base0D = "#000000",
    base0E = "#A0A0A0",
    base0F = "#000000",
  },
  colors = {
    red = "#E25D56",
    green = "#00a137",
    blue = "#33a3ff",
    yellow = "#ff8f33",
    accent = "#000000",
  },
}

M.base_30 = {
  white = theme.schema.base0F,
  darker_black = Color.lerp(theme.schema.base00, "#000000", 0.08), --
  black = theme.schema.base01, --  nvim bg
  black2 = Color.lerp(theme.schema.base00, "#000000", 0.03),
  one_bg = Color.lerp(theme.schema.base00, "#000000", 0.04),
  one_bg2 = theme.colors.yellow,
  one_bg3 = theme.colors.yellow,
  grey = Color.lerp(theme.schema.base00, "#000000", 0.2),
  grey_fg = Color.lerp(theme.schema.base00, "#000000", 0.2),
  grey_fg2 = "#ff00ff",
  light_grey = Color.lerp(theme.schema.base00, "#000000", 0.5),
  red = theme.colors.red,
  baby_pink = theme.colors.red,
  pink = "#d8a8ff",
  line = theme.schema.base01, -- for lines like vertsplit
  green = theme.colors.accent,
  green1 = Color.lerp(theme.colors.green, "#ff0000", 1),
  vibrant_green = "#bfd8b2",
  blue = theme.colors.blue,
  nord_blue = theme.colors.blue,
  yellow = theme.schema.base0B,
  sun = theme.colors.yellow,
  purple = "#d8a8ff",
  dark_purple = "#d8a8ff",
  teal = theme.colors.blue,
  orange = "#ff0000",
  cyan = theme.colors.blue,
  statusline_bg = Color.lerp(theme.schema.base00, "#000000", 0.04),
  lightbg = Color.lerp(theme.schema.base00, "#000000", 0.1),
  pmenu_bg = Color.lerp(theme.schema.base00, "#000000", 0.1),
  folder_bg = Color.lerp(theme.schema.base00, "#000000", 0.5),
}

M.base_16 = theme.schema

M.polish_hl = {
  defaults = {
    ["@parameter"] = { fg = M.base_30.white },
    ["@keyword"] = { fg = M.base_16.base04 },
    ["@variable"] = { fg = M.base_30.white },
    ["@field.key"] = { fg = M.base_30.green1 },
    ["@field"] = { fg = M.base_30.white },
    ["@text"] = { fg = M.base_30.white },
    ["@keyword.return"] = { fg = M.base_16.base04 },
    ["@keyword.function"] = { fg = M.base_16.base04 },
    ["@type.builtin"] = { fg = theme.colors.accent },
    ["Type"] = { fg = M.base_30.white },
    ["@none"] = { fg = M.base_30.white },
    ["@property"] = { fg = M.base_30.white },
    Include = { fg = M.base_16.base0E },
    Normal = { fg = M.base_30.white },
    PmenuSel = { fg = "NONE", bold = true },
    Search = { bg = Color.lerp(theme.colors.yellow, theme.schema.base00, 0.7), fg = "NONE" },
    ["@tag.delimiter"] = { fg = M.base_16.base04 },
  },
  git = {
    Changed = { fg = theme.colors.yellow },
    Added = { fg = theme.colors.green },
    Deleted = { fg = theme.colors.red },
  },
  nvimtree = {
    NvimTreeGitNew = { fg = theme.colors.green },
    NvimTreeExecFile = { fg = theme.colors.green },
    NvimTreeGitStaged = { fg = theme.colors.green },
    NvimTreeGitDirty = { fg = theme.colors.yellow },
  },
  lsp = {
    -- warn
    DiagnosticUnderlineWarn = {
      bg = Color.lerp(theme.colors.yellow, theme.schema.base00, 0.9),
      undercurl = true,
      sp = theme.colors.yellow,
    },
    DiagnosticWarn = { fg = theme.colors.yellow },
    DiagnosticVirtualTextWarn = {
      fg = theme.colors.yellow,
      bg = Color.lerp(theme.colors.yellow, theme.schema.base00, 0.9),
    },
    -- info
    DiagnosticUnderlineInfo = {
      bg = Color.lerp(theme.colors.blue, theme.schema.base00, 0.9),
      undercurl = true,
      sp = theme.colors.blue,
    },
    DiagnosticInfo = { fg = theme.colors.blue },
    DiagnosticVirtualTextInfo = {
      fg = theme.colors.blue,
      bg = Color.lerp(theme.colors.blue, theme.schema.base00, 0.9),
    },
    --error
    DiagnosticUnderlineError = {
      bg = Color.lerp(theme.colors.red, theme.schema.base00, 0.9),
      undercurl = true,
      sp = theme.colors.red,
    },
    DiagnosticError = { fg = theme.colors.red },
    DiagnosticVirtualTextError = {
      fg = theme.colors.red,
      bg = Color.lerp(theme.colors.red, theme.schema.base00, 0.9),
    },
    -- end
  },
}

M.add_hl = {
  ["@tag.attribute.tsx"] = { fg = M.base_16.base04 },
  ["@punctuation.special"] = { fg = M.base_16.base04 },
  ["@punctuation.bracket"] = { fg = theme.colors.accent },
}

M.type = "dark"

M = require("base46").override_theme(M, "söd_light")

return M
