local M = {}

M.getNextCycleValue = function(list, currentIndex)
	local nextIndex = (currentIndex % #list) + 1
	return list[nextIndex]
end
M.indexOf = function(list, value)
	for i, v in ipairs(list) do
		if v == value then
			return i
		end
	end
	return nil
end

M.is_buffer_in_tabline = function(buf_id)
	return vim.bo[buf_id].buflisted
end

M.get_buffers = function()
	local buffers = {}

	for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
		if M.is_buffer_in_tabline(buffer) then
			table.insert(buffers, buffer)
		end
	end

	return buffers
end

return M
