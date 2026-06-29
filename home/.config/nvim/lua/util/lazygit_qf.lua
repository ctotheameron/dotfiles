-- Open files selected via lazygit's `e` command as normal buffers in the parent
-- Neovim (instead of tabs), replace the quickfix list with the selection, and
-- surface it in Trouble. Called over RPC from ~/.config/lazygit/nvim-edit.sh,
-- which lazygit invokes via os.edit / os.editAtLine.

local M = {}

-- A normal (listed, non-floating, non-terminal) window to open files into —
-- never the lazygit float itself. Prefer the previously-focused window, which
-- is also where snacks restores focus when lazygit closes.
local function target_win()
  local function is_normal(win)
    if not (win and win ~= 0 and vim.api.nvim_win_is_valid(win)) then
      return false
    end
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      return false -- floating
    end
    return vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
  end

  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if is_normal(prev) then
    return prev
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_normal(win) then
      return win
    end
  end
  return nil
end

---Open the given files and replace the quickfix list with them.
---@param files string[] absolute file paths
---@param line integer 1-based line to jump to, or 0 for none
function M.open(files, line)
  if type(files) ~= "table" then
    files = { files }
  end
  if #files == 0 then
    return ""
  end
  local lnum = (line and line > 0) and line or nil

  -- We're invoked from the lazygit float (a floating terminal). Grab its job so
  -- we can close lazygit afterwards — stopping the job makes lazygit exit, which
  -- triggers snacks' auto-close and returns focus to the editing window.
  local from = vim.api.nvim_get_current_win()
  local from_buf = vim.api.nvim_win_get_buf(from)
  local lazygit_job
  if vim.api.nvim_win_get_config(from).relative ~= "" and vim.bo[from_buf].buftype == "terminal" then
    lazygit_job = vim.b[from_buf].terminal_job_id
  end

  local win = target_win()
  if not win then
    vim.cmd("botright vsplit")
    win = vim.api.nvim_get_current_win()
  end

  -- Open the files in the target window without taking focus from lazygit: the
  -- first becomes the active buffer there; the rest become loaded, listed
  -- buffers (so they show up like any normally-opened file).
  vim.api.nvim_win_call(win, function()
    for i, file in ipairs(files) do
      if i == 1 then
        vim.cmd.edit(vim.fn.fnameescape(file))
        if lnum then
          pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
        end
      else
        local buf = vim.fn.bufadd(file)
        vim.fn.bufload(buf)
        vim.bo[buf].buflisted = true
      end
    end
  end)

  -- Replace the quickfix list with the selection.
  local items = {}
  for _, file in ipairs(files) do
    items[#items + 1] = { filename = file, lnum = lnum or 1, col = 1 }
  end
  vim.fn.setqflist({}, "r", { title = "lazygit", items = items })

  -- Surface it in Trouble without stealing focus from the editing window.
  pcall(function()
    require("trouble").open({ mode = "quickfix", focus = false })
  end)

  -- Close lazygit (deferred so the RPC returns first): stopping its job makes it
  -- exit like pressing `q`, so snacks closes the float and lands us on the file.
  if lazygit_job then
    vim.schedule(function()
      pcall(vim.fn.jobstop, lazygit_job)
    end)
  end

  return ""
end

return M
