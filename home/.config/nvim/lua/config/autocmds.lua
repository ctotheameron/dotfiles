-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("SnacksPickerNetrwReplacement", { clear = true }),
  desc = "Open Snacks files picker when opening a directory",
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    if vim.fn.isdirectory(bufname) == 1 then
      -- Wipe the empty directory buffer so it doesn't linger
      vim.api.nvim_buf_delete(args.buf, { force = true })
      -- Open standard Snacks file picker targeted to that directory
      Snacks.picker.files({ cwd = bufname })
    end
  end,
})
