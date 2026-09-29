-- Load all theme plugins so switching is instant, and follow `theme set` live
local config_dir = vim.fn.expand("~/.config")
local theme_file = config_dir .. "/theme/neovim.lua"
local specs = {}
local seen = {}

local function current_colorscheme()
  local ok, theme = pcall(dofile, theme_file)
  if ok and type(theme) == "table" then
    for _, entry in ipairs(theme) do
      if type(entry) == "table" and entry.opts and entry.opts.colorscheme then
        return entry.opts.colorscheme
      end
    end
  end
end

-- Collect plugins from all themes
local themes_dir = config_dir .. "/themes"
local handle = vim.uv.fs_scandir(themes_dir)
if handle then
  while true do
    local name, typ = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if typ == "directory" then
      local path = themes_dir .. "/" .. name .. "/neovim.lua"
      local ok, theme = pcall(dofile, path)
      if ok and type(theme) == "table" then
        for _, entry in ipairs(theme) do
          if type(entry) == "table" and entry[1] and entry[1]:match("/") then
            local key = entry[1]
            if not seen[key] then
              seen[key] = true
              specs[#specs + 1] = { entry[1], name = entry.name, priority = entry.priority, lazy = true }
            end
          end
        end
      end
    end
  end
end

-- Set colorscheme from current theme
local colorscheme = current_colorscheme()
if colorscheme then
  specs[#specs + 1] = { "LazyVim/LazyVim", opts = { colorscheme = colorscheme } }
end

-- `theme set` rewrites theme_file; lazy.nvim loads the (lazy) plugin on :colorscheme
local poll = vim.uv.new_fs_poll()
if poll then
  poll:start(theme_file, 1000, function(err)
    if err then
      return
    end
    vim.schedule(function()
      local name = current_colorscheme()
      if name and name ~= vim.g.colors_name then
        pcall(vim.cmd.colorscheme, name)
      end
    end)
  end)
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      poll:stop()
    end,
  })
end

return specs
