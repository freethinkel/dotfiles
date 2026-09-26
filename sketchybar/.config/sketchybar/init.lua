require("bar")
require("default")
require("items")

function inspect(t, indent)
	indent = indent or 0
	local spacing = string.rep("  ", indent)

	if type(t) ~= "table" then
		return tostring(t)
	end

	local result = "{\n"
	for key, value in pairs(t) do
		result = result .. spacing .. "  " .. tostring(key) .. " = "
		if type(value) == "table" then
			result = result .. inspect(value, indent + 1)
		else
			result = result .. tostring(value)
		end
		result = result .. ",\n"
	end
	result = result .. spacing .. "}"
	return result
end

function trim(s)
	return s:match("^%s*(.-)%s*$")
end

function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end
