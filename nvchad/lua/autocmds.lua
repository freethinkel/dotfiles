vim.api.nvim_create_autocmd("FileType", {
  pattern = "nvdash",
  callback = function(data)
    vim.keymap.set("n", "s", function()
      require("persistence").load()
    end, {
      buffer = data.buf,
    })
  end,
})

vim.cmd "au BufNewFile,BufRead *.pcss set ft=scss"
vim.cmd "au BufNewFile,BufRead *.mdx set ft=markdown"

vim.api.nvim_create_autocmd({ "DirChanged", "WinEnter", "BufEnter" }, {
  pattern = "*",
  callback = function()
    vim.fn.system('zellij action rename-tab "' .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. '"')
  end,
})
