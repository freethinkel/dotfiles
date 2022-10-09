local M = {}

M.setup = function() end
local status, comment = pcall(require, "Comment")
if not status then
	return
end

comment.setup({})
return M
