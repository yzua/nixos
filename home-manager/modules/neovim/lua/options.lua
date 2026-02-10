-- General editor settings.

-- Leader key (spacebar) — prefix for custom keybindings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Line numbers
vim.opt.number = true -- Show absolute line numbers
vim.opt.relativenumber = true -- Also show relative numbers (helps with jumping)

-- Tabs and indentation (vim-sleuth auto-detects per file, these are defaults)
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 2 -- Spaces per indentation level
vim.opt.tabstop = 2 -- Spaces a tab character displays as
vim.opt.smartindent = true -- Auto-indent new lines

-- Search
vim.opt.ignorecase = true -- Case-insensitive search...
vim.opt.smartcase = true -- ...unless you type a capital letter
vim.opt.hlsearch = true -- Highlight all search matches
vim.opt.incsearch = true -- Show matches as you type

-- Display
vim.opt.termguicolors = true -- True color support
vim.opt.signcolumn = "yes" -- Always show sign column (git/diagnostics)
vim.opt.cursorline = true -- Highlight the current line
vim.opt.scrolloff = 8 -- Keep 8 lines visible above/below cursor
vim.opt.wrap = false -- Don't wrap long lines

-- Behavior
vim.opt.mouse = "a" -- Enable mouse support (scroll, click, select)
vim.opt.clipboard = "unnamedplus" -- Use system clipboard (wl-copy on Wayland)
vim.opt.undofile = true -- Persistent undo (survives closing the file)
vim.opt.swapfile = false -- No swap files
vim.opt.splitright = true -- New vertical splits open to the right
vim.opt.splitbelow = true -- New horizontal splits open below
vim.opt.updatetime = 250 -- Faster updates for diagnostics (ms)
vim.opt.timeoutlen = 300 -- Time to wait for key sequence (ms)
