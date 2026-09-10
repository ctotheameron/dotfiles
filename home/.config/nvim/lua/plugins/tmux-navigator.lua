-- Ctrl-hjkl navigation across nvim splits and tmux panes. One mapping
-- table drives both sides.
--
-- vim-tmux-navigator in tmux.conf passes Ctrl-hjkl through to nvim when
-- the pane runs vim. nvim always moves first. Only at a split edge does
-- the key leave nvim and go to tmux.
local function navigate(wincmd, direction)
  local previous = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= previous then
    return
  end

  if vim.env.TMUX ~= nil and vim.env.TMUX ~= "" then
    local command = {
      left = "TmuxNavigateLeft",
      down = "TmuxNavigateDown",
      up = "TmuxNavigateUp",
      right = "TmuxNavigateRight",
    }
    pcall(vim.cmd, command[direction])
  end
end

local function go(wincmd, direction)
  return function()
    navigate(wincmd, direction)
  end
end

return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  init = function()
    -- This file owns the mappings, so the plugin must not add its own.
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = {
    { "<C-h>", go("h", "left"), desc = "Navigate left (nvim/tmux)" },
    { "<C-j>", go("j", "down"), desc = "Navigate down (nvim/tmux)" },
    { "<C-k>", go("k", "up"), desc = "Navigate up (nvim/tmux)" },
    -- mode "t" so the rightward handoff also works from terminal buffers,
    -- which otherwise swallow the key. Only <C-l> needs this: terminals sit
    -- at the right edge in this layout, and the other directions land on
    -- regular nvim windows.
    { "<C-l>", go("l", "right"), mode = { "n", "t" }, desc = "Navigate right (nvim/tmux)" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate to previous pane" },
  },
}
