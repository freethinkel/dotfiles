---@diagnostic disable: different-requires
local cmp = require('cmp')

local misc_icons = {
  Robot = "󰚩",
  Squirrel = "",
  Tag = "",
  Watch = "",
  Smiley = "",
  Package = "",
  CircuitBoard = "",
}

local duplicates = {
  buffer = 1,
  path = 1,
  nvim_lsp = 0,
  luasnip = 1,
}

local duplicates_default = 0

local kind_icons = {
  Array = "",
  Boolean = "",
  Class = "",
  Color = "",
  Constant = "",
  Constructor = "",
  Enum = "",
  EnumMember = "",
  Event = "",
  Field = "",
  File = "",
  Folder = "󰉋",
  Function = "",
  Interface = "",
  Key = "",
  Keyword = "",
  Method = "",
  Module = "",
  Namespace = "",
  Null = "󰟢",
  Number = "",
  Object = "",
  Operator = "",
  Package = "",
  Property = "",
  Reference = "",
  Snippet = "",
  String = "",
  Struct = "",
  Text = "",
  TypeParameter = "",
  Unit = "",
  Value = "",
  Variable = "",
}
local source_names = {
  nvim_lsp = "(LSP)",
  emoji = "(Emoji)",
  path = "(Path)",
  calc = "(Calc)",
  cmp_tabnine = "(Tabnine)",
  vsnip = "(Snippet)",
  luasnip = "(Snippet)",
  buffer = "(Buffer)",
  tmux = "(TMUX)",
  copilot = "(Copilot)",
  treesitter = "(TreeSitter)",
}

local git_icons = {
  LineAdded = "",
  LineModified = "",
  LineRemoved = "",
  FileDeleted = "",
  FileIgnored = "◌",
  FileRenamed = "",
  FileStaged = "S",
  FileUnmerged = "",
  FileUnstaged = "",
  FileUntracked = "U",
  Diff = "",
  Repo = "",
  Octoface = "",
  Branch = "",
}

---@diagnostic disable-next-line: redundant-parameter

cmp.setup({
  completion = { completeopt = 'menu,menuone,noinsert' },
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  formatting = {
    fields = { "kind", "abbr", "menu" },
    max_width = 0,
    format = function(entry, vim_item)
      local max_width = 0
      if max_width ~= 0 and #vim_item.abbr > max_width then
        vim_item.abbr = string.sub(vim_item.abbr, 1, max_width - 1) .. ""
      end
      vim_item.kind = kind_icons[vim_item.kind]

      if entry.source.name == "copilot" then
        vim_item.kind = git_icons.Octoface
        vim_item.kind_hl_group = "CmpItemKindCopilot"
      end

      if entry.source.name == "cmp_tabnine" then
        vim_item.kind = misc_icons.Robot
        vim_item.kind_hl_group = "CmpItemKindTabnine"
      end

      if entry.source.name == "crates" then
        vim_item.kind = misc_icons.Package
        vim_item.kind_hl_group = "CmpItemKindCrate"
      end

      if entry.source.name == "lab.quick_data" then
        vim_item.kind = misc_icons.CircuitBoard
        vim_item.kind_hl_group = "CmpItemKindConstant"
      end

      if entry.source.name == "emoji" then
        vim_item.kind = misc_icons.Smiley
        vim_item.kind_hl_group = "CmpItemKindEmoji"
      end
      vim_item.menu = source_names[entry.source.name]
      vim_item.dup = duplicates[entry.source.name]
          or duplicates_default
      return vim_item
    end,
  },

  mapping = {
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    },
    ["<C-n>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
    ["<C-p>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif require("luasnip").jumpable(-1) then
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
        else
          fallback()
        end
      end,
      {
        "i",
        "s",
      }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif require("luasnip").jumpable(-1) then
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
        else
          fallback()
        end
      end,
      {
        "i",
        "s",
      }),
  },
  sources = {
    { name = "luasnip" },
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "nvim_lua" },
    { name = "path" },
  }
})
