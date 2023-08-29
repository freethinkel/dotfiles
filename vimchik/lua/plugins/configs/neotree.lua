require("neo-tree").setup({
  popup_border_style = "rounded",
  enable_git_status = true,
  enable_diagnostics = true,
  filesystem = {
    follow_current_file = true,
    components = {
      name = function(config, node, state)
        local highlight = config.highlight or "Normal"
        if node.type == "directory" then
          highlight = "Normal"
        end
        if node:get_depth() == 1 then
          highlight = "Normal"
        else
          if config.use_git_status_colors == nil or config.use_git_status_colors then
            local git_status = state.components.git_status({}, node, state)
            if git_status and git_status.highlight then
              highlight = git_status.highlight
            end
          end
        end
        return {
          text = node.name,
          highlight = highlight,
        }
      end

    }
  },
  default_component_configs = {
    indent = {
      with_markers = true,
      indent_marker = "▏",
      last_indent_marker = "▏",
      indent_size = 2,
    },
    icon = {
      folder_closed = "󰉋",
      folder_open = "",
      folder_empty = "",
      default = "",
    },
    git_status = {
      symbols = {
        added = "A",
        deleted = "D",
        modified = "M",
        renamed = "R",
        untracked = "U",
        ignored = "I",
        unstaged = "U",
        staged = "S",
        conflict = "C",
      },
    },
  },
  source_selector = {
    winbar = true,     -- toggle to show selector on winbar
    statusline = true, -- toggle to show selector on statusline
    show_scrolled_off_parent_node = false,
    sources = {
      { source = "filesystem", display_name = " 󰉓  Files " },
      { source = "git_status", display_name = "   Git " },
    },
  },
  document_symbols = {
    kinds = {
      File = { icon = "󰈙", hl = "Tag" },
      Namespace = { icon = "󰌗", hl = "Include" },
      Package = { icon = "󰏖", hl = "Label" },
      Class = { icon = "󰌗", hl = "Include" },
      Property = { icon = "󰆧", hl = "@property" },
      Enum = { icon = "󰒻", hl = "@number" },
      Function = { icon = "󰊕", hl = "Function" },
      String = { icon = "󰀬", hl = "String" },
      Number = { icon = "󰎠", hl = "Number" },
      Array = { icon = "󰅪", hl = "Type" },
      Object = { icon = "󰅩", hl = "Type" },
      Key = { icon = "󰌋", hl = "" },
      Struct = { icon = "󰌗", hl = "Type" },
      Operator = { icon = "󰆕", hl = "Operator" },
      TypeParameter = { icon = "󰊄", hl = "Type" },
      StaticMethod = { icon = '󰠄 ', hl = 'Function' },
    }
  },
  window = {
    position = "left",
    width = 40,
    mapping_options = {
      noremap = true,
      nowait = true,
    },
    mappings = {
      ["l"] = "open"
    }
  }
})
