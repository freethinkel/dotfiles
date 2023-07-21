require('nvim-treesitter.configs').setup({
  auto_install = true,
  ensure_installed = { "lua" },
  highlight = {
    enable = true,
  },
  context_commentstring = {
    enable = true,
    enable_autocmd = false,
    config = {
      -- Languages that have a single comment style
      typescript = "// %s",
      css = "/* %s */",
      scss = "/* %s */",
      html = "<!-- %s -->",
      svelte = "<!-- %s -->",
      vue = "<!-- %s -->",
      json = "",
    },
  },
  textobjects = {
    swap = {
      enable = true,
    },
    select = {
      enable = true,
    },
  },
  textsubjects = {
    enable = true,
    keymaps = { ["."] = "textsubjects-smart", [";"] = "textsubjects-big" },
  },
  indent = { enable = true, disable = { "yaml", "python" } },
  rainbow = {
    enable = false,
    extended_mode = true,  -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
    max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
  },
})
