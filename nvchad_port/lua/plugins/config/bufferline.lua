local M = {}

M.setup = function()
  local status, bufferline = pcall(require, 'bufferline')
  if not status then
    return
  end

  bufferline.setup({
    options = {
      offsets = {
        {
          filetype = "NvimTree",
          text = "Explorer",
          highlight = "Directory",
          text_align = "left"
        }
      }
    }
  })
end

return M
