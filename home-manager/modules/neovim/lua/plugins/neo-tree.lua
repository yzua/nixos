-- Neo-tree sidebar file explorer (like VSCode sidebar).

require("neo-tree").setup({
  close_if_last_window = true,
  enable_git_status = true,
  enable_diagnostics = true,
  filesystem = {
    follow_current_file = { enabled = true },
    filtered_items = {
      hide_dotfiles = false,
      hide_gitignored = false,
    },
  },
  window = {
    width = 35,
    position = "left",
  },
})

vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file explorer" })
