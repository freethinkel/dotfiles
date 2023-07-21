local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<leader>h"] = { ":nohl<cr>", opts = { silent = true } },
    -- Move current line / block with Alt-j/k a la vscode.
    ["<A-j>"] = { ":m .+1<CR>==", "Move down" },
    ["<A-k>"] = { ":m .-2<CR>==", "Move up", },
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

M.tabufline = {
  plugin = true,
  n = {
    ["H"] = { function() require("core.ui.tabufline").tabuflinePrev() end, "Tab prev" },
    ["L"] = { function() require("core.ui.tabufline").tabuflineNext() end, "Tab next" },
    ["<leader>c"] = { function() require("core.ui.tabufline").close_buffer() end, "Tab next" },
  }
}

M.lsp = {
  n = {
    ["<leader>la"] = { "<cmd>Lspsaga code_action<cr>", "Code action" },
    ["<leader>lc"] = { "<cmd>Lspsaga show_cursor_diagnostics<cr>", "Cursor diagnistic" },
    ["<leader>lr"] = { "<cmd>Lspsaga rename<cr>", "Rename" },
    ["<leader>lj"] = { "<cmd>Lspsaga diagnostic_jump_next<cr>", "Next diagnistic" },
    ["<leader>lk"] = { "<cmd>Lspsaga diagnostic_jump_prev<cr>", "Prev diagnistic" },
    ["gd"] = { "<cmd>Lspsaga goto_definition<cr>", "Goto definition" },
    ["gp"] = { "<cmd>Lspsaga peek_definition<cr>", "Peek definition" },
    ["gr"] = { "<cmd>Lspsaga finder<cr>", "Lsp finder" },
    ["K"] = { "<cmd>Lspsaga hover_doc<cr>", "LSP Hover" },
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

--   ["<leader>ls"] = {
--     function()
--       vim.lsp.buf.signature_help()
--     end,
--     "LSP signature help",
--   },
--
--
--   ["<leader>ra"] = {
--     function()
--       require("nvchad_ui.renamer").open()
--     end,
--     "LSP rename",
--   },
--
--
--   ["<leader>f"] = {
--     function()
--       vim.diagnostic.open_float { border = "rounded" }
--     end,
--     "Floating diagnostic",
--   },
--
--   ["[d"] = {
--     function()
--       vim.diagnostic.goto_prev { float = { border = "rounded" } }
--     end,
--     "Goto prev",
--   },
--
--   ["]d"] = {
--     function()
--       vim.diagnostic.goto_next { float = { border = "rounded" } }
--     end,
--     "Goto next",
--   },
--
--   ["<leader>q"] = {
--     function()
--       vim.diagnostic.setloclist()
--     end,
--     "Diagnostic setloclist",
--   },
--
--   ["<leader>wa"] = {
--     function()
--       vim.lsp.buf.add_workspace_folder()
--     end,
--     "Add workspace folder",
--   },
--
--   ["<leader>wr"] = {
--     function()
--       vim.lsp.buf.remove_workspace_folder()
--     end,
--     "Remove workspace folder",
--   },
--
--   ["<leader>wl"] = {
--     function()
--       print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
--     end,
--     "List workspace folders",
--   },
-- },


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
