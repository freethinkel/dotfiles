local M = {}

M.merge_tb = function(a, b)
  if type(a) == 'table' and type(b) == 'table' then
    for k, v in pairs(b) do if type(v) == 'table' and type(a[k] or false) == 'table' then merge(a[k], v) else a[k] = v end end
  end
  return a
end

M.setup_lazy = function()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end

M.colorscheme = function(theme, opt)
  local config = opt or {}
  local safe_set_theme = function()
    vim.cmd.colorscheme(theme)
  end;

  pcall(safe_set_theme)

  if config.transparent then
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalSB", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  end
end

return M
