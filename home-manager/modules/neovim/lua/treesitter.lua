-- Treesitter syntax highlighting.
-- Grammars are pre-compiled by Nix — no download needed.

vim.treesitter.start = vim.treesitter.start or function() end
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
