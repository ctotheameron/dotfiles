-- Seamless Ctrl-hjkl navigation between nvim splits and tmux panes.
-- Counterpart to the tmux plugin (vim-tmux-navigator in tmux.conf): tmux
-- passes Ctrl-hjkl through to nvim when the pane runs vim, and this plugin
-- hands off to tmux when there's no nvim split in the requested direction.
return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left (nvim/tmux)" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down (nvim/tmux)" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up (nvim/tmux)" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right (nvim/tmux)" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate to previous pane" },
  },
}
