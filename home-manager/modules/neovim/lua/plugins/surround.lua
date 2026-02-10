-- nvim-surround - Add/change/delete surrounding characters.

require("nvim-surround").setup({
  -- Use default keymaps:
  -- ys{motion}{char} - add surrounding
  -- ds{char} - delete surrounding
  -- cs{old}{new} - change surrounding
  -- yss{char} - surround entire line
  -- yS{motion}{char} - surround on new lines
  -- ySS{char} - surround line on new lines
  -- In visual mode: S{char}
})
