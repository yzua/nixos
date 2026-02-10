-- LSP configuration and keybindings.
-- Servers are installed system-wide via Home Manager (see lsp-servers.nix).

local map = vim.keymap.set
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- LSP keybindings — only active when a language server is attached
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = function(desc)
      return { buffer = ev.buf, desc = desc }
    end
    map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
    map("n", "gr", vim.lsp.buf.references, opts("Find references"))
    map("n", "K", vim.lsp.buf.hover, opts("Hover documentation"))
    map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename symbol"))
    map("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code actions"))
    map("n", "<leader>d", vim.diagnostic.open_float, opts("Show diagnostics"))
    map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, opts("Previous diagnostic"))
    map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, opts("Next diagnostic"))
  end,
})

-- LSP server configs (vim.lsp.config API — nvim 0.11+)

-- TypeScript / JavaScript
vim.lsp.config.ts_ls = { capabilities = capabilities }

-- Rust
vim.lsp.config.rust_analyzer = { capabilities = capabilities }

-- Zig
vim.lsp.config.zls = { capabilities = capabilities }

-- Lua (configured to know about the vim global)
vim.lsp.config.lua_ls = {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
    },
  },
}

-- Nix
vim.lsp.config.nixd = { capabilities = capabilities }

-- Go
vim.lsp.config.gopls = { capabilities = capabilities }

-- Python
vim.lsp.config.pyright = { capabilities = capabilities }

-- Bash
vim.lsp.config.bashls = { capabilities = capabilities }

-- YAML
vim.lsp.config.yamlls = { capabilities = capabilities }

-- TOML
vim.lsp.config.taplo = { capabilities = capabilities }

-- Markdown
vim.lsp.config.marksman = { capabilities = capabilities }

-- Svelte
vim.lsp.config.svelte = { capabilities = capabilities }

-- HTML (from vscode-langservers-extracted)
vim.lsp.config.html = { capabilities = capabilities }

-- CSS (from vscode-langservers-extracted)
vim.lsp.config.cssls = { capabilities = capabilities }

-- JSON (from vscode-langservers-extracted)
vim.lsp.config.jsonls = { capabilities = capabilities }

-- ESLint (from vscode-langservers-extracted)
vim.lsp.config.eslint = { capabilities = capabilities }

-- Emmet
vim.lsp.config.emmet_language_server = { capabilities = capabilities }

-- TailwindCSS
vim.lsp.config.tailwindcss = { capabilities = capabilities }

-- Dockerfile
vim.lsp.config.dockerls = { capabilities = capabilities }

-- GraphQL
vim.lsp.config.graphql = { capabilities = capabilities }

-- C/C++ (clangd from clang-tools)
vim.lsp.config.clangd = { capabilities = capabilities }

-- Enable all configured servers
vim.lsp.enable({
  "ts_ls", "rust_analyzer", "zls", "lua_ls", "nixd",
  "gopls", "pyright", "bashls", "yamlls", "taplo",
  "marksman", "svelte", "html", "cssls", "jsonls",
  "eslint", "emmet_language_server", "tailwindcss",
  "dockerls", "graphql", "clangd",
})
