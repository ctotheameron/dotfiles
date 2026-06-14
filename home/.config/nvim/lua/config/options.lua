-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Show a vertical ruler at column 80
vim.opt.colorcolumn = "80"

-- Indentation: 2-space, expand tabs, keep indent on new lines
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Allow project-local .nvim.lua / .exrc files
vim.o.exrc = true
