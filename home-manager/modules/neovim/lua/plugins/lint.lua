-- nvim-lint - Async linting with diagnostics.

require("lint").linters_by_ft = {
  javascript = { "biomejs" },
  typescript = { "biomejs" },
  typescriptreact = { "biomejs" },
  javascriptreact = { "biomejs" },
  python = { "ruff" },
  go = { "golangcilint" },
  nix = { "statix" },
  bash = { "shellcheck" },
  sh = { "shellcheck" },
  markdown = { "markdownlint" },
  c = { "cppcheck" },
  cpp = { "cppcheck" },
}

-- Lint on save and insert leave
vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
