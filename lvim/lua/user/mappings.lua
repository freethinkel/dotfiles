lvim.keys.insert_mode["jj"]                = "<esc>"
lvim.keys.insert_mode["kj"]                = "<esc>"
lvim.keys.insert_mode["Kj"]                = "<esc>"
lvim.keys.insert_mode["jk"]                = "<esc>"
lvim.keys.insert_mode["Jk"]                = "<esc>"
lvim.keys.normal_mode["<S-l>"]             = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"]             = ":BufferLineCyclePrev<CR>"

lvim.keys.normal_mode["<C-p>"]             = ":Telescope<cr>"

lvim.builtin.which_key.mappings["l"]["a"]  = {
  "<cmd>Lspsaga code_action<cr>",
  "Code actions",
}
lvim.builtin.which_key.mappings["l"]["r"]  = {
  "<cmd>Lspsaga rename<cr>",
  "Rename",
}
lvim.builtin.which_key.mappings["l"]["c"]  = {
  "<cmd>Lspsaga show_cursor_diagnostics<cr>",
  "Show cursor diagnostic",
}
lvim.builtin.which_key.mappings["l"]["j"]  = {
  "<cmd>Lspsaga diagnostic_jump_next<cr>",
  "Show cursor diagnostic",
}
lvim.builtin.which_key.mappings["l"]["k"]  = {
  "<cmd>Lspsaga diagnostic_jump_prev<cr>",
  "Show cursor diagnostic",
}
lvim.lsp.buffer_mappings.normal_mode["gd"] = { "<cmd>Lspsaga goto_definition<cr>", "Goto definitions" }
lvim.lsp.buffer_mappings.normal_mode["gp"] = { "<cmd>Lspsaga peek_definition<cr>", "Peek definitions" }
lvim.lsp.buffer_mappings.normal_mode["gr"] = { "<cmd>Lspsaga finder<cr>", "Goto references" }
lvim.lsp.buffer_mappings.normal_mode["K"]  = { "<cmd>Lspsaga hover_doc<cr>", "Show hover" }

lvim.builtin.which_key.mappings["F"]       = {
  name = "Flutter",
  e = { ":FlutterEmulators<cr>", "FlutterEmulators" },
  r = { ":FlutterRun<cr>", "FlutterRun" },
  q = { ":FlutterQuit<cr>", "FlutterQuit" },
  R = { ":FlutterRestart<cr>", "FlutterRestart" },
  C = { ":FlutterLogClear<cr>", "FlutterLogClear" },
}

lvim.builtin.which_key.mappings["g"]["h"]  = {
  function()
    local view = require("diffview.lib").get_current_view()
    if view then
      vim.cmd("DiffviewClose")
    else
      vim.cmd("DiffviewFileHistory %")
    end
  end,
  "Git file history",
}
lvim.builtin.which_key.mappings['g']['m']  = {
  function()
    local view = require("diffview.lib").get_current_view()
    if view then
      vim.cmd("DiffviewClose")
    else
      vim.cmd("DiffviewOpen")
    end
  end,
  "Toggle Diffview",
}

lvim.builtin.which_key.mappings['d']['s']  = {
  function()
    if vim.bo.filetype == "dart" then
      vim.cmd("FlutterRun")
    else
      require("dap").continue()
    end
  end,
  "Start"
}
