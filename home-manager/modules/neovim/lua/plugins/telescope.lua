-- Telescope fuzzy finder (like Ctrl+P in VSCode).

local builtin = require("telescope.builtin")

require("telescope").setup({
  defaults = {
    file_ignore_patterns = { "node_modules", ".git/" },
  },
})

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
