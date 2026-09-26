return {
  {
    "conform.nvim",
    opts = function(_, opts)
      local util = require("conform.util")

      opts.formatters_by_ft = opts.formatters_by_ft or {}

      if LazyVim.has_extra("formatting.prettier") then
        opts.formatters_by_ft.astro = { "prettier" }
      end

      -- Projects that ship an .oxfmtrc.json get oxfmt, everything else keeps
      -- prettier. The binary comes from the project's node_modules so the
      -- editor and `bun run format` never disagree on the version.
      opts.formatters = opts.formatters or {}
      opts.formatters.oxfmt = {
        command = util.from_node_modules("oxfmt"),
        args = { "--stdin-filepath", "$FILENAME" },
        stdin = true,
        cwd = util.root_file({ ".oxfmtrc.json", ".oxfmtrc.jsonc" }),
        require_cwd = true,
      }

      for _, ft in ipairs({
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "jsonc",
      }) do
        opts.formatters_by_ft[ft] = { "oxfmt", "prettier", stop_after_first = true }
      end
    end,
  },
}
