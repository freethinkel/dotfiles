local theme_file = vim.fn.expand("~/.config/slicker/theme/neovim.lua")

local function load_theme()
  local ok, theme = pcall(dofile, theme_file)
  if ok and type(theme) == "table" then
    return theme
  end
  return {}
end

local function get_colorscheme(theme)
  for _, entry in ipairs(theme) do
    if type(entry) == "table" and entry.opts and entry.opts.colorscheme then
      return entry.opts.colorscheme
    end
  end
  return nil
end

local function apply_theme()
  local theme = load_theme()
  local colorscheme = get_colorscheme(theme)
  if colorscheme and colorscheme ~= vim.g.colors_name then
    pcall(vim.cmd.colorscheme, colorscheme)
  end
end

local function watch_theme()
  local poll = vim.uv.new_fs_poll()
  if not poll then
    return
  end

  poll:start(theme_file, 1000, function(err)
    if not err then
      vim.schedule(apply_theme)
    end
  end)

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      poll:stop()
    end,
  })
end

watch_theme()

return load_theme()
