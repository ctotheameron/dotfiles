-- Seamless Ctrl-hjkl navigation between nvim splits, herdr panes and tmux
-- panes. One mapping table drives all three.
--
-- The multiplexer half of the handoff:
--   * tmux  — vim-tmux-navigator in tmux.conf passes Ctrl-hjkl through to nvim
--     when the pane runs vim, and this plugin hands off to tmux at an edge.
--   * herdr — the vim-herdr-navigation plugin does the same job, wired to
--     ctrl+hjkl in ~/.config/herdr/config.toml. install.sh installs it.
--     Logic below follows its editor/nvim.lua (MIT, paulbkim-dev).
--
-- nvim always moves first. Only at a split edge does the key leave nvim, and
-- then herdr wins over tmux, because herdr panes sit inside a tmux pane here.
local function navigate(wincmd, direction)
  local previous = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= previous then
    return
  end

  local pane = vim.env.HERDR_PANE_ID
  if pane ~= nil and pane ~= "" then
    -- Name this pane. `--current` means the server's focused pane, which is
    -- not always the pane nvim runs in.
    local herdr = vim.env.HERDR_BIN_PATH
    if herdr == nil or herdr == "" then
      herdr = "herdr"
    end
    vim.system({ herdr, "pane", "focus", "--direction", direction, "--pane", pane })
  elseif vim.env.TMUX ~= nil and vim.env.TMUX ~= "" then
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
    { "<C-h>", go("h", "left"), desc = "Navigate left (nvim/herdr/tmux)" },
    { "<C-j>", go("j", "down"), desc = "Navigate down (nvim/herdr/tmux)" },
    { "<C-k>", go("k", "up"), desc = "Navigate up (nvim/herdr/tmux)" },
    -- mode "t" so the rightward handoff also works from terminal buffers,
    -- which otherwise swallow the key. Only <C-l> needs this: terminals sit
    -- at the right edge in this layout, and the other directions land on
    -- regular nvim windows.
    { "<C-l>", go("l", "right"), mode = { "n", "t" }, desc = "Navigate right (nvim/herdr/tmux)" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate to previous pane" },
  },
}
