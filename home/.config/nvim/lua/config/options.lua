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

-- Keep the personal word list inside this repo, so `zg` additions reach every
-- machine. Left empty, Neovim writes to ~/.local/share/nvim/site/spell, which
-- is machine-local state and never gets committed.
-- LazyVim turns spell on for text, gitcommit, markdown, plaintex and typst.
local spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
vim.opt.spellfile = spellfile

-- Only the `.add` source is tracked. Neovim reads the compiled `.spl` and
-- never builds it on its own, so a fresh clone would flag every added word.
-- Build it when it is missing or older than the source. `zg` keeps both in
-- step after that, so this normally does nothing.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  group = vim.api.nvim_create_augroup("spellfile_compile", { clear = true }),
  callback = function()
    local add = vim.uv.fs_stat(spellfile)
    if not add then
      return
    end

    local spl = vim.uv.fs_stat(spellfile .. ".spl")
    if spl and spl.mtime.sec >= add.mtime.sec then
      return
    end

    pcall(vim.cmd, "silent mkspell! " .. vim.fn.fnameescape(spellfile))
  end,
})
