---@type Base46Table
local M = {}

local Color = require "utils.color"

local theme = {
  schema = {
    base00 = "#1B1B1B",
    base01 = "#262626",
    base02 = "#3C3C3C",
    base03 = "#3C3C3C",
    base04 = "#5f5f5f",
    base05 = "#A0A0A0",
    base06 = "#E9E9E9",
    base07 = "#A9F0FD",
    base08 = "#FFFFFF", -- just foreground
    base09 = "#FFFFFF",
    base0A = "#A0A0A0",
    base0B = "#404141",
    base0C = "#A0A0A0",
    base0D = "#A0A0A0",
    base0E = "#A0A0A0",
    base0F = "#FFFFFF",
  },
  colors = {
    red = "#FA7583",
    green = "#9FECB7",
    blue = "#9BCAFF",
    yellow = "#ffc799",
    accent = "#FFFFFF",
  },
}

M.base_30 = {
  white = theme.schema.base0F,
  darker_black = Color.lerp(theme.schema.base00, "#000000", 0.1), --
  black = theme.schema.base01, --  nvim bg
  black2 = Color.lerp(theme.schema.base00, "#ffffff", 0.03),
  one_bg = Color.lerp(theme.schema.base00, "#ffffff", 0.04),
  one_bg2 = theme.colors.yellow,
  one_bg3 = theme.colors.yellow,
  grey = Color.lerp(theme.schema.base00, "#ffffff", 0.2),
  grey_fg = Color.lerp(theme.schema.base00, "#ffffff", 0.2),
  grey_fg2 = "#ff00ff",
  light_grey = Color.lerp(theme.schema.base00, "#ffffff", 0.5),
  red = theme.colors.red,
  baby_pink = theme.colors.red,
  pink = "#d8a8ff",
  line = theme.schema.base01, -- for lines like vertsplit
  green = theme.colors.accent,
  green1 = Color.lerp(theme.colors.green, "#ff0000", 1),
  vibrant_green = "#bfd8b2",
  blue = theme.colors.blue,
  nord_blue = theme.colors.blue,
  yellow = "#fffeaa",
  sun = theme.colors.yellow,
  purple = "#d8a8ff",
  dark_purple = "#d8a8ff",
  teal = theme.colors.blue,
  orange = "#ff0000",
  cyan = theme.colors.blue,
  statusline_bg = Color.lerp(theme.schema.base00, "#ffffff", 0.04),
  lightbg = Color.lerp(theme.schema.base00, "#ffffff", 0.1),
  pmenu_bg = Color.lerp(theme.schema.base00, "#ffffff", 0.1),
  folder_bg = Color.lerp(theme.schema.base00, "#ffffff", 0.5),
}

M.base_16 = theme.schema

M.polish_hl = {
  defaults = {
    ["@parameter"] = { fg = M.base_30.white },
    ["@keyword"] = { fg = M.base_16.base0F, bold = true },
    ["@keyword.lua"] = { fg = M.base_16.base0F, bold = true },
    ["@variable"] = { fg = M.base_30.white },
    ["@field.key"] = { fg = M.base_30.green1 },
    ["@field"] = { fg = M.base_30.white },
    ["@text"] = { fg = M.base_30.white },
    ["@keyword.return"] = { fg = M.base_16.base04 },
    ["@keyword.function"] = { fg = M.base_16.base04 },
    ["@type.builtin"] = { fg = theme.colors.accent },
    ["Type"] = { fg = M.base_30.white },
    ["@none"] = { fg = M.base_30.white },
    ["@property"] = { fg = M.base_16.base04 },
    ["@property.lua"] = { fg = M.base_16.base04 },
    ["@punctuation.bracket"] = { fg = M.base_16.base04 },
    ["@punctuation.bracket.lua"] = { fg = M.base_16.base04 },
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
    DiagnosticHint = { fg = theme.colors.blue },
    DiagnosticVirtualTextHint = {
      fg = theme.colors.blue,
      bg = Color.lerp(theme.colors.blue, theme.schema.base00, 0.9),
    },
    DiagnosticUnderlineHint = {
      bg = Color.lerp(theme.colors.blue, theme.schema.base00, 0.9),
      undercurl = true,
      sp = theme.colors.blue,
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
  ["@punctuation.bracket"] = { fg = M.base_16.base04 },
  ["@punctuation.bracket.lua"] = { fg = M.base_16.base04 },
}

M.type = "dark"

M = require("base46").override_theme(M, "söd")

return M
