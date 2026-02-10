-- Diagnostic display configuration.

vim.diagnostic.config({
  virtual_text = true, -- Show inline diagnostic messages
  signs = true, -- Show signs in the gutter
  underline = true, -- Underline problematic code
  update_in_insert = false, -- Don't update while typing
  float = {
    border = "rounded",
    source = true, -- Show which LSP produced the diagnostic
  },
})
