vim.treesitter.language.register("html", "ejs")
vim.treesitter.language.register("javascript", "ejs")
vim.treesitter.language.register("cpp", "conf")
vim.treesitter.language.register("cpp", "fsharp")
vim.filetype.add({ extension = { ypp = "ypp" } })
vim.treesitter.language.register("cpp", "ypp")
vim.treesitter.language.register("cpp", "lex")

return { {
  "nvim-treesitter/nvim-treesitter",
} }
