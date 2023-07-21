local M = {}
local merge_tb = vim.tbl_deep_extend

M.merge_tb = function(a, b)
  if type(a) == 'table' and type(b) == 'table' then
    for k, v in pairs(b) do if type(v) == 'table' and type(a[k] or false) == 'table' then merge(a[k], v) else a[k] = v end end
  end
  return a
end

M.get_hl = function(name)
  local hl = vim.api.nvim_get_hl_by_name(name, {})

  return { fg = hl.foreground, bg = hl.background }
end

M.hi = function(name, options)
  vim.api.nvim_set_hl(0, name, options)

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    pattern = { "*" },
    callback = function()
      vim.api.nvim_set_hl(0, name, options)
    end,
  })
end

M.load_highlights = function(hightlights)
  for _, v in pairs(hightlights) do
    for key, value in pairs(v) do
      M.hi(key, value)
    end
  end
end


M.setup_plugins = function(plugins)
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
  require("lazy").setup(plugins)
end

M.load_mappings = function(section, mappings)
  local mappings = mappings or require("core.mappings")
  vim.schedule(function()
    local function set_section_map(section_values)
      if section_values.plugin then
        return
      end

      section_values.plugin = nil

      for mode, mode_values in pairs(section_values) do
        local default_opts = merge_tb("force", { mode = mode }, mapping_opt or {})
        for keybind, mapping_info in pairs(mode_values) do
          -- merge default + user opts
          local opts = merge_tb("force", default_opts, mapping_info.opts or {})

          mapping_info.opts, opts.mode = nil, nil
          opts.desc = mapping_info[2]

          vim.keymap.set(mode, keybind, mapping_info[1], opts)
        end
      end
    end

    if type(section) == "string" then
      mappings[section]["plugin"] = nil
      mappings = { mappings[section] }
    end

    for _, sect in pairs(mappings) do
      set_section_map(sect)
    end
  end)
end

M.set_theme = function(theme)
  pcall(vim.cmd, "colorscheme " .. theme)
end

return M
