local M = {}

M.merge_tb = function(a, b)
  if type(a) == 'table' and type(b) == 'table' then
    for k, v in pairs(b) do if type(v) == 'table' and type(a[k] or false) == 'table' then merge(a[k], v) else a[k] = v end end
  end
  return a
end

M.setup_packer = function(plugins)
  local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
      fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
      vim.cmd [[packadd packer.nvim]]
      return true
    end
    return false
  end

  local packer_bootstrap = ensure_packer()

  return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    for k, v in pairs(plugins) do
      use(M.merge_tb({ k }, v))
    end

    if packer_bootstrap then
      require('packer').sync()
    end
  end)
end

M.set_theme = function(config)
  vim.cmd.colorscheme(config.theme)
  if config.transparent then
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  end
end

M.set_map = function(config, options)
  local status, wk = pcall(require, "plugins.configs.which_key")
  if not status then
    return
  end
  wk.register(config, options)
end

return M
