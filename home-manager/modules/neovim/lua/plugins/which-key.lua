-- Which-Key — shows available keybindings when you press leader.

local wk = require("which-key")
wk.setup({})

-- Register key groups so which-key shows helpful labels
wk.add({
  { "<leader>f", group = "Find" },
  { "<leader>c", group = "Code" },
  { "<leader>r", group = "Rename" },
})
