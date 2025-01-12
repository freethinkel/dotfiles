local function filter_lines(input)
  local lines = {}
  for line in input:gmatch("[^\r\n]+") do
    if not line:match("^.+//") then
      table.insert(lines, line)
    end
  end
  return table.concat(lines, "\n")
end

local read_vscode_config = function()
  local file_path = vim.fn.getcwd() .. "/.vscode/launch.json"

  local file = io.open(file_path, "r") -- Open the file in read mode
  if not file then
    print("Could not open file: " .. file_path)
    return nil
  end

  local content = file:read("*all") -- Read the entire file content
  file:close() -- Close the file
  content = filter_lines(content)
  return vim.json.decode(content)
end

local get_config = function()
  local vscode_config = read_vscode_config()

  print("VS")
  -- vim.print(vscode_config)

  if not vscode_config then
    return {} -- DEFAULT
  end

  local configs = {}

  for k, config in pairs(vscode_config.configurations) do
    configs[k] = config
    configs[k].flutter_mode = config.flutterMode
  end

  return configs
end

vim.print(get_config())
