-- conform.nvim - Format on save with proper fallback chains.

require("conform").setup({
  formatters_by_ft = {
    javascript = { "biome" },
    typescript = { "biome" },
    typescriptreact = { "biome" },
    javascriptreact = { "biome" },
    json = { "biome" },
    python = { "ruff_format" },
    go = { "gofumpt", "golines" },
    nix = { "nixfmt" },
    rust = { "rustfmt" },
    lua = { "stylua" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    zig = { "zigfmt" },
    bash = { "shfmt" },
    sh = { "shfmt" },
    c = { "clang-format" },
    cpp = { "clang-format" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})

-- Format keybinding
vim.keymap.set({ "n", "v" }, "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
