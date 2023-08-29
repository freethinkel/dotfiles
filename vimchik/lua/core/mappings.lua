local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<leader>h"] = { ":nohl<cr>", opts = { silent = true } },
    -- Move current line / block with Alt-j/k a la vscode.
    ["<A-j>"] = { ":m .+1<CR>==", "Move down" },
    ["<A-k>"] = { ":m .-2<CR>==", "Move up", },
    ["<leader>qq"] = { ":qa!<cr>" }
  },
  i = {
    ["kj"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
    ["jj"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
    ["jk"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
  },
  x = {
    ["<A-j>"] = { ":m '>+1<CR>gv-gv", "Move down", opts = { noremap = true, silent = true } },
    ["<A-k>"] = { ":m '<-2<CR>gv-gv", "Move up", opts = { noremap = true, silent = true } },
  },
  v = {
    ["<"] = { "<gv", "", opts = { noremap = true, silent = true } },
    [">"] = { ">gv", "", opts = { noremap = true, silent = true } },
  }
}

M.git = {
  n = {
    ["<leader>gg"] = { function() require("modules.lazygit").toggle() end, "Open lazygit" }
  }
}

M.explorer = {
  n = {
    ["<leader>e"] = { ":Neotree<cr>", "Focus nvimtree", opts = { silent = true } }
  }
}

M.bufferline = {
  plugin = true,
  n = {
    ["H"] = { "<cmd>BufferLineCyclePrev<cr>", "Tab prev" },
    ["L"] = { "<cmd>BufferLineCycleNext<cr>", "Tab next" },
    ["<leader>c"] = { function()
      require("core.utils").close_buffer()
    end, "Close buffer" },
  }
}

M.lsp = {
  plugin = true,
  n = {
    ["gd"] = { vim.lsp.buf.definition, "Goto definition" },
    ["gi"] = { vim.lsp.buf.implementation, "Goto implementation" },
    ["gt"] = { vim.lsp.buf.type_definition, "Goto type definition" },
    ["gr"] = { vim.lsp.buf.references, "Goto references" },
    ["K"] = { vim.lsp.buf.hover, "LSP Hover" },
    ["<leader>la"] = { vim.lsp.buf.code_action, "Code action" },
    ["<leader>lc"] = { "<cmd>Lspsaga show_cursor_diagnostics<cr>", "Cursor diagnistic" },
    ["<leader>lr"] = { vim.lsp.buf.rename, "Rename" },
    ["<leader>lj"] = { vim.diagnostic.goto_next, "Next diagnistic" },
    ["<leader>lk"] = { vim.diagnostic.goto_prev, "Prev diagnistic" },
    ["<leader>ll"] = { "<cmd>Telescope diagnostics<cr>", "List diagnostics" },
  }
}

M.dap = {
  plugin = true,
  n = {
    ["<leader>du"] = {
      function()
        vim.cmd("NeoTreeClose");
        require("dapui").toggle();
      end,
      "Toggle dap ui"
    }
  }
}

-- M.lsp = {
--   plugin = true,
--   n = {
--     ["<leader>la"] = { "<cmd>Lspsaga code_action<cr>", "Code action" },
--     ["<leader>lc"] = { "<cmd>Lspsaga show_cursor_diagnostics<cr>", "Cursor diagnistic" },
--     ["<leader>lr"] = { "<cmd>Lspsaga rename<cr>", "Rename" },
--     ["<leader>lj"] = { "<cmd>Lspsaga diagnostic_jump_next<cr>", "Next diagnistic" },
--     ["<leader>lk"] = { "<cmd>Lspsaga diagnostic_jump_prev<cr>", "Prev diagnistic" },
--     ["gd"] = { "<cmd>Lspsaga goto_definition<cr>", "Goto definition" },
--     ["gp"] = { "<cmd>Lspsaga peek_definition<cr>", "Peek definition" },
--     ["gr"] = { "<cmd>Lspsaga finder<cr>", "Lsp finder" },
--     ["K"] = { "<cmd>Lspsaga hover_doc<cr>", "LSP Hover" },
--   }
-- }

M.flutter = {
  n = {
    ["<leader>FF"] = { function() require('telescope').extensions.flutter.commands() end, "Flutter commands" },
    ["<leader>Fe"] = { ":FlutterEmulators<cr>", "FlutterEmulators" },
    ["<leader>Fr"] = { ":FlutterRun<cr>", "FlutterRun" },
    ["<leader>Fq"] = { ":FlutterQuit<cr>", "FlutterQuit" },
    ["<leader>FR"] = { ":FlutterRestart<cr>", "FlutterRestart" },
    ["<leader>FC"] = { ":FlutterLogClear<cr>", "FlutterLogClear" },
  }
}

M.zen_mode = {
  n = {
    ["<leader>zz"] = { ":ZenMode<cr>", "Zen mode" }
  }
}

M.spectre = {
  n = {
    ["<leader>sr"] = { function() require("spectre").open() end, "Spectre" }
  }
}

M.telescope = {
  plugin = true,

  n = {
    -- find
    ["<leader>sf"] = { "<cmd> Telescope find_files <CR>", "Find files" },
    ["<leader>fa"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "Find all" },
    ["<leader>st"] = { "<cmd> Telescope live_grep <CR>", "Live grep" },
    ["<leader>ss"] = { "<cmd> Telescope current_buffer_fuzzy_find <CR>", "Find in current buffer" },
    ["<leader>p"] = { "<cmd> Telescope<CR>", "Telescope" }
  },
}

M.comment = {
  plugin = true,

  -- toggle comment in both modes
  n = {
    ["<leader>/"] = {
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      "Toggle comment",
    },
  },

  v = {
    ["<leader>/"] = {
      "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
      "Toggle comment",
    },
  },
}

M.blankline = {
  plugin = true,

  n = {
    ["<leader>cc"] = {
      function()
        local ok, start = require("indent_blankline.utils").get_current_context(
          vim.g.indent_blankline_context_patterns,
          vim.g.indent_blankline_use_treesitter_scope
        )

        if ok then
          vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { start, 0 })
          vim.cmd [[normal! _]]
        end
      end,

      "Jump to current context",
    },
  },
}

return M
