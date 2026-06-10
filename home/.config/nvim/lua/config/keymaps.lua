-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move selected lines up/down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- ⌘+j (ghostty sends Alt+j) → sesh session picker.
-- Inside tmux this mapping is unreachable: tmux's root `M-j` binding catches
-- the key before nvim sees it. This covers running nvim *outside* tmux —
-- opens a floating terminal with the picker, then attaches tmux in the float.
vim.keymap.set({ "n", "t" }, "<M-j>", function()
  local picker = [[
    session=$(sesh list --icons --hide-duplicates | fzf \
      --height 100% --reverse \
      --no-sort --prompt '⚡  ' \
      --bind 'tab:down,btab:up' \
      --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
      --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
      --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
      --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
      --preview-window 'right:60%' \
      --preview 'sesh preview {}')
    [ -n "$session" ] && sesh connect "$session"
  ]]
  Snacks.terminal({ "zsh", "-c", picker }, {
    win = { border = "rounded", width = 0.8, height = 0.7 },
  })
end, { desc = "Sesh session picker" })
