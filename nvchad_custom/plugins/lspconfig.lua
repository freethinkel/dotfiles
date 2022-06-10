local M = {}

M.setup_lsp = function(attach, capabilities)
   local lspconfig = require "lspconfig"

   -- lspservers with default config
   local servers = { "html", "cssls", "clangd", "svelte", "tsserver", "dartls", "rust_analyzer" }

   for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup {
         on_attach = function(client)
           attach(client)
           if (lsp == 'tsserver') then
            client.resolved_capabilities.document_formatting = false
            client.resolved_capabilities.document_range_formatting = false
           end
         end,
         capabilities = capabilities,
      }
   end
end

return M
