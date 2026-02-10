-- Autopairs — auto-close brackets and quotes.

local autopairs = require("nvim-autopairs")
autopairs.setup({ check_ts = true }) -- Use treesitter for smarter pairing

-- Integrate with nvim-cmp (auto-add closing bracket after completion)
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
