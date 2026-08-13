-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move selected lines up/down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Join lines without moving the cursor
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- Keep cursor centered when half-page scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centered)" })

-- Keep search results centered with folds opened
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- Diagnostic jumps without the float. LazyVim passes `float = true`, so `]d`
-- showed each message twice: once in a float, and once in the virtual lines
-- under the cursor line. vim.diagnostic.jump opens no float of its own, so
-- these maps only drop that flag. `<leader>cd` still opens the float by hand.
local function diagnostic_jump(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
    })
  end
end

vim.keymap.set("n", "]d", diagnostic_jump(1), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_jump(-1), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "]e", diagnostic_jump(1, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_jump(-1, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_jump(1, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_jump(-1, "WARN"), { desc = "Prev Warning" })

-- Paste over selection without clobbering the yank register
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste (keep register)" })

-- Yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })

-- Delete without yanking
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete (no yank)" })

-- Make Ctrl-C behave like a real Escape in insert mode
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Escape" })

-- Disable Ex mode
vim.keymap.set("n", "Q", "<nop>", { desc = "Disabled (Ex mode)" })

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
