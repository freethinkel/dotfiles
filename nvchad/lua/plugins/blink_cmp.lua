return {
  {
    "nvim-cmp",
    enabled = false,
  },
  {
    "saghen/blink.cmp",
    lazy = false,
    -- lazy loading handled internally
    -- optional: provides snippets for the snippet source
    dependencies = {
      "rafamadriz/friendly-snippets",
      "giuxtaposition/blink-cmp-copilot",
      "windwp/nvim-autopairs",
      {
        "saghen/blink.compat",
        optional = true, -- make optional so it's only enabled if any extras need it
        opts = {},
        version = "*",
      },
    },

    -- use a release tag to download pre-built binaries
    version = "v0.*",
    opts_extend = {
      "sources.completion.enabled_providers",
      "sources.compat",
      "sources.default",
    },
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' for mappings similar to built-in completion
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
      -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      -- see the "default configuration" section below for full documentation on how to define
      -- your own keymap.
      keymap = {
        preset = "enter",
        -- ["<Tab>"] = {
        --   LazyVim.cmp.map { "snippet_forward", "ai_accept" },
        --   "fallback",
        -- },
      },
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release
        use_nvim_cmp_as_default = true,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "normal",
      },
      enabled = function()
        return vim.bo.buftype ~= "prompt" and vim.bo.buftype ~= "nofile"
      end,
      completion = {
        trigger = {
          show_on_trigger_character = false,
        },
        accept = {
          -- experimental auto-brackets support
          auto_brackets = {
            enabled = true,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = {
          enabled = false,
        },
        enabled_providers = { "lsp", "path", "snippets", "buffer", "copilot" },
        menu = {
          draw = {
            treesitter = true,
            columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  return ctx.icon_gap .. ctx.kind_icon .. ctx.icon_gap
                end,
                highlight = function(ctx)
                  return (require("blink.cmp.completion.windows.render.tailwind").get_hl(ctx) or "BlinkCmpKind")
                    .. ctx.kind
                end,
              },
            },
          },
        },
      },
      -- default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, via `opts_extend`
      sources = {
        completion = {
          enabled_providers = { "lsp", "path", "snippets", "buffer", "copilot" },
        },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            kind = "Copilot",
          },
        },
      },

      -- experimental auto-brackets support
      -- completion = { accept = { auto_brackets = { enabled = true } } }

      -- experimental signature help support
      -- signature = { enabled = true }
    },
    -- allows extending the providers array elsewhere in your config
    -- without having to redefine it
  },
}
