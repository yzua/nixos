-- Comment.nvim — toggle comments.
-- gcc = toggle line comment, gc in visual = toggle selection.
-- Ctrl+/ also works (like VSCode).

local map = vim.keymap.set

require("Comment").setup({})

-- Ctrl+/ to toggle comments (terminals send Ctrl+/ as <C-_>)
map("n", "<C-_>", function()
  require("Comment.api").toggle.linewise.current()
end, { desc = "Toggle comment" })
map("v", "<C-_>", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", { desc = "Toggle comment" })
-- Some modern terminals send <C-/> directly
map("n", "<C-/>", function()
  require("Comment.api").toggle.linewise.current()
end, { desc = "Toggle comment" })
map("v", "<C-/>", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", { desc = "Toggle comment" })
