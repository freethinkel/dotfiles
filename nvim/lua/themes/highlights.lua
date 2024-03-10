local M = {}

local hi = require("themes.utils").hi
local get_hi = require("themes.utils").get_hi
local mixColors = require("themes.utils").mixColors

M.setup = function(theme)
	-- vim.cmd("hi clear")
	vim.cmd(":set termguicolors")
	vim.o.termguicolors = true
	-- vim.g.colors_name = theme.name
	--
	local schema = theme.schema
	local colors = theme.colors

	local tint_background = mixColors(schema.base00, "#000000", 0.1)

	-- General
	hi("Normal", { bg = schema.base00 })
	hi("SignColumn", { link = "Normal" })
	hi("LineNr", { fg = schema.base04 })
	hi("VertSplit", { fg = tint_background, bg = tint_background })
	hi("Directory", { fg = schema.base04 })

	-- Mini statusline
	hi("MiniStatuslineModeNormal", { fg = schema.base00, bg = colors.blue })
	hi("MiniStatuslineModeInsert", { fg = schema.base00, bg = mixColors(colors.red, colors.blue, 0.2) })
	hi("MiniStatuslineModeVisual", { fg = schema.base00, bg = colors.yellow })
	hi("MiniStatuslineModeCommand", { fg = colors.yellow, bg = schema.base01 })
	hi("MiniStatuslineDevInfo", { fg = colors.accent, bg = schema.base01 })
	hi("MiniStatuslineFileInfo", { fg = colors.accent, bg = schema.base01 })
	hi("MiniStatuslineFilename", { fg = schema.base05, bg = schema.base01 })

	-- lsp
	hi("DiagnosticError", { bg = mixColors(colors.red, schema.base00, 0.9), fg = colors.red })
	hi("DiagnosticSignError", { bg = "none", fg = colors.red })
	hi(
		"DiagnosticUnderlineError",
		{ bg = mixColors(colors.red, schema.base00, 0.9), undercurl = true, sp = colors.red }
	)

	hi("DiagnosticWarn", { bg = mixColors(colors.yellow, schema.base00, 0.9), fg = colors.yellow })
	hi("DiagnosticSignWarn", { bg = "none", fg = colors.yellow })
	hi(
		"DiagnosticUnderlineWarn",
		{ bg = mixColors(colors.yellow, schema.base00, 0.9), undercurl = true, sp = colors.yellow }
	)

	hi("DiagnosticHint", { bg = mixColors(colors.blue, schema.base00, 0.9), fg = colors.blue })
	hi("DiagnosticSignHint", { bg = "none", fg = colors.blue })
	hi(
		"DiagnosticUnderlineHint",
		{ bg = mixColors(colors.blue, schema.base00, 0.9), undercurl = true, sp = colors.blue }
	)

	hi("DiagnosticInfo", { bg = mixColors(colors.green, schema.base00, 0.9), fg = colors.green })
	hi("DiagnosticSignInfo", { bg = "none", fg = colors.green })
	hi(
		"DiagnosticUnderlineInfo",
		{ bg = mixColors(colors.green, schema.base00, 0.9), undercurl = true, sp = colors.green }
	)

	hi("SpellCap", { undercurl = true, sp = colors.blue })
	hi("Bold", { bold = true })
	hi("Debug", { fg = schema.base08 })
	hi("Error", { fg = schema.base00, bg = schema.base08 })
	hi("ErrorMsg", { fg = schema.base08, bg = schema.base00 })
	hi("Exception", { fg = schema.base08 })
	hi("FoldColumn", { fg = schema.base0C, bg = schema.base01 })
	hi("Folded", { fg = schema.base03, bg = schema.base01 })
	hi("IncSearch", { fg = schema.base01, bg = schema.base09 })
	hi("Italic", { italic = true })
	hi("Macro", { fg = schema.base08 })
	hi("MatchParen", { bg = schema.base03 })
	hi("ModeMsg", { fg = schema.base0B })
	hi("MoreMsg", { fg = schema.base0B })
	hi("Question", { fg = schema.base0D })
	hi("Search", { bg = mixColors(colors.yellow, schema.base00, 0.7) })
	hi("Substitute", { fg = schema.base01, bg = schema.base0A })
	hi("SpecialKey", { fg = schema.base03 })
	hi("TooLong", { fg = schema.base08 })
	hi("Underlined", { fg = schema.base08 })
	hi("Visual", { bg = schema.base02 })
	hi("VisualNOS", { fg = schema.base08 })
	hi("WarningMsg", { fg = schema.base08 })
	hi("WildMenu", { fg = schema.base08, bg = schema.base0A })
	hi("Title", { fg = schema.base0D })
	hi("Conceal", { fg = schema.base0D, bg = schema.base00 })
	hi("Cursor", { fg = schema.base00, bg = schema.base05 })
	hi("CursorLine", { bg = schema.base01 })
	hi("CursorLineNr", { fg = schema.base06, bold = true })
	hi("CursorLineSign", { fg = schema.base06 })
	hi("NonText", { fg = schema.base03 })

	hi("StatusLine", { fg = schema.base04, bg = schema.base00 })
	hi("StatusLineNC", { fg = schema.base03, bg = schema.base01 })
	hi("ColorColumn", { bg = get_hi("Normal").bg })
	hi("CursorColumn", { bg = get_hi("Normal").bg })

	hi("QuickFixLine", { bg = schema.base01 })
	hi("PMenu", { fg = schema.base05, bg = schema.base01 })
	hi("PMenuSel", { fg = schema.base01, bg = schema.base05 })
	hi("TabLine", { fg = schema.base03, bg = schema.base01 })
	hi("TabLineFill", { fg = schema.base03, bg = schema.base01 })
	hi("TabLineSel", { fg = schema.base0B, bg = schema.base01 })

	-- NvimTree
	hi("NvimTreeGitFileNewHL", { fg = colors.green })
	hi("NvimTreeGitFolderDirtyHL", { fg = colors.yellow })
	hi("NvimTreeGitFolderDeletedHL", { fg = mixColors(colors.red, schema.base05, 0.4) })
	hi("NvimTreeGitFolderStagedHL", { fg = colors.yellow })
	hi("NvimTreeFolderIcon", { link = "Directory" })
	hi("NvimTreeNormal", { bg = tint_background })
	hi("NvimTreeWindowPicker", { bg = colors.blue, fg = schema.base00 })

	-- Syntax
	hi("Boolean", { fg = schema.base09 })
	hi("Character", { fg = schema.base08 })
	hi("Comment", { fg = schema.base03 })
	hi("Conditional", { fg = schema.base0E })
	hi("Constant", { fg = schema.base09 })
	hi("Define", { fg = schema.base0E })
	hi("Delimiter", { fg = schema.base0F })
	hi("Float", { fg = schema.base09 })
	hi("Function", { fg = schema.base0D })
	hi("Identifier", { fg = schema.base08 })
	hi("Include", { fg = schema.base0D })
	hi("Keyword", { fg = schema.base0E })
	hi("Label", { fg = schema.base0A })
	hi("Number", { fg = schema.base09 })
	hi("Operator", { fg = schema.base05 })
	hi("PreProc", { fg = schema.base0A })
	hi("Repeat", { fg = schema.base0A })
	hi("Special", { fg = schema.base0C })
	hi("SpecialChar", { fg = schema.base0F })
	hi("Statement", { fg = schema.base08 })
	hi("StorageClass", { fg = schema.base0A })
	hi("String", { fg = schema.base0B })
	hi("Structure", { fg = schema.base0E })
	hi("Tag", { fg = schema.base0A })
	hi("Todo", { fg = schema.base0A })
	hi("Type", { fg = schema.base0A })
	hi("Typedef", { fg = schema.base0A })

	-- C highlighting
	hi("cOperator", { fg = schema.base0C })
	hi("cPreCondit", { fg = schema.base0E })

	-- C# highlighting
	hi("csClass", { fg = schema.base0A })
	hi("csAttribute", { fg = schema.base0A })
	hi("csModifier", { fg = schema.base0E })
	hi("csType", { fg = schema.base08 })
	hi("csUnspecifiedStatement", { fg = schema.base0D })
	hi("csContextualStatement", { fg = schema.base0E })
	hi("csNewDecleration", { fg = schema.base08 })

	-- CSS highlighting
	hi("cssBraces", { fg = schema.base05 })
	hi("cssClassName", { fg = schema.base0E })
	hi("cssColor", { fg = schema.base0C })

	-- Diff highlighting
	hi("DiffAdd", { fg = schema.base0B, bg = schema.base01 })
	hi("DiffChange", { fg = schema.base03, bg = schema.base01 })
	hi("DiffDelete", { fg = schema.base08, bg = schema.base01 })
	hi("DiffText", { fg = schema.base0D, bg = schema.base01 })
	hi("DiffAdded", { fg = schema.base0B, bg = schema.base00 })
	hi("DiffFile", { fg = schema.base08, bg = schema.base00 })
	hi("DiffNewFile", { fg = schema.base0B, bg = schema.base00 })
	hi("DiffLine", { fg = schema.base0D, bg = schema.base00 })
	hi("DiffRemoved", { fg = schema.base08, bg = schema.base00 })

	-- Git highlighting
	hi("gitcommitOverflow", { fg = schema.base08 })
	hi("gitcommitSummary", { fg = schema.base0B })
	hi("gitcommitComment", { fg = schema.base03 })
	hi("gitcommitUntracked", { fg = schema.base03 })
	hi("gitcommitDiscarded", { fg = schema.base03 })
	hi("gitcommitSelected", { fg = schema.base03 })
	hi("gitcommitHeader", { fg = schema.base0E })
	hi("gitcommitSelectedType", { fg = schema.base0D })
	hi("gitcommitUnmergedType", { fg = schema.base0D })
	hi("gitcommitDiscardedType", { fg = schema.base0D })
	hi("gitcommitBranch", { fg = schema.base09 })
	hi("gitcommitUntrackedFile", { fg = schema.base0A })
	hi("gitcommitUnmergedFile", { fg = schema.base08 })
	hi("gitcommitDiscardedFile", { fg = schema.base08 })
	hi("gitcommitSelectedFile", { fg = schema.base0B })

	-- GitGutter highlighting
	hi("GitGutterAdd", { fg = colors.green })
	hi("GitGutterChange", { fg = colors.blue })
	hi("GitGutterDelete", { fg = colors.red })
	hi("GitGutterChangeDelete", { fg = colors.red })

	-- HTML highlighting
	hi("htmlBold", { fg = schema.base0A })
	hi("htmlItalic", { fg = schema.base0E })
	hi("htmlEndTag", { fg = schema.base05 })
	hi("htmlTag", { fg = schema.base05 })

	-- JavaScript highlighting
	hi("javaScript", { fg = schema.base05 })
	hi("javaScriptBraces", { fg = schema.base05 })
	hi("javaScriptNumber", { fg = schema.base09 })
	-- pangloss/vim-javascript highlighting
	hi("jsOperator", { fg = schema.base0D })
	hi("jsStatement", { fg = schema.base0E })
	hi("jsReturn", { fg = schema.base0E })
	hi("jsThis", { fg = schema.base08 })
	hi("jsClassDefinition", { fg = schema.base0A })
	hi("jsFunction", { fg = schema.base0E })
	hi("jsFuncName", { fg = schema.base0D })
	hi("jsFuncCall", { fg = schema.base0D })
	hi("jsClassFuncName", { fg = schema.base0D })
	hi("jsClassMethodType", { fg = schema.base0E })
	hi("jsRegexpString", { fg = schema.base0C })
	hi("jsGlobalObjects", { fg = schema.base0A })
	hi("jsGlobalNodeObjects", { fg = schema.base0A })
	hi("jsExceptions", { fg = schema.base0A })
	hi("jsBuiltins", { fg = schema.base0A })

	-- Mail highlighting
	hi("mailQuoted1", { fg = schema.base0A })
	hi("mailQuoted2", { fg = schema.base0B })
	hi("mailQuoted3", { fg = schema.base0E })
	hi("mailQuoted4", { fg = schema.base0C })
	hi("mailQuoted5", { fg = schema.base0D })
	hi("mailQuoted6", { fg = schema.base0A })
	hi("mailURL", { fg = schema.base0D })
	hi("mailEmail", { fg = schema.base0D })

	-- Markdown highlighting
	hi("markdownCode", { fg = schema.base0B })
	hi("markdownError", { fg = schema.base05, bg = schema.base00 })
	hi("markdownCodeBlock", { fg = schema.base0B })
	hi("markdownHeadingDelimiter", { fg = schema.base0D })

	-- NERDTree highlighting
	hi("NERDTreeDirSlash", { fg = schema.base0D })
	hi("NERDTreeExecFile", { fg = schema.base05 })

	-- PHP highlighting
	hi("phpMemberSelector", { fg = schema.base05 })
	hi("phpComparison", { fg = schema.base05 })
	hi("phpParent", { fg = schema.base05 })
	hi("phpMethodsVar", { fg = schema.base0C })

	-- Python highlighting
	hi("pythonOperator", { fg = schema.base0E })
	hi("pythonRepeat", { fg = schema.base0E })
	hi("pythonInclude", { fg = schema.base0E })
	hi("pythonStatement", { fg = schema.base0E })

	-- Ruby highlighting
	hi("rubyAttribute", { fg = schema.base0D })
	hi("rubyConstant", { fg = schema.base0A })
	hi("rubyInterpolationDelimiter", { fg = schema.base0F })
	hi("rubyRegexp", { fg = schema.base0C })
	hi("rubySymbol", { fg = schema.base0B })
	hi("rubyStringDelimiter", { fg = schema.base0B })

	-- SASS highlighting
	hi("sassidChar", { fg = schema.base08 })
	hi("sassClassChar", { fg = schema.base09 })
	hi("sassInclude", { fg = schema.base0E })
	hi("sassMixing", { fg = schema.base0E })
	hi("sassMixinName", { fg = schema.base0D })

	-- Signify highlighting
	hi("SignifySignAdd", { fg = schema.base0B })
	hi("SignifySignChange", { fg = schema.base0D })
	hi("SignifySignDelete", { fg = schema.base08 })

	-- Spelling highlighting
	hi("SpellBad", { sp = schema.base08, undercurl = true })
	hi("SpellLocal", { undercurl = true, sp = schema.base0C })
	hi("SpellCap", { undercurl = true, sp = schema.base0D })
	hi("SpellRare", { undercurl = true, sp = schema.base0E })

	-- Startify highlighting
	hi("StartifyBracket", { fg = schema.base03 })
	hi("StartifyFile", { fg = schema.base07 })
	hi("StartifyFooter", { fg = schema.base03 })
	hi("StartifyHeader", { fg = schema.base0B })
	hi("StartifyNumber", { fg = schema.base09 })
	hi("StartifyPath", { fg = schema.base03 })
	hi("StartifySection", { fg = schema.base0E })
	hi("StartifySelect", { fg = schema.base0C })
	hi("StartifySlash", { fg = schema.base03 })
	hi("StartifySpecial", { fg = schema.base03 })

	-- Java highlighting
	hi("javaOperator", { fg = schema.base0D })
end

return M
