-- pi is installed as a global npm package under the home-default asdf node and
-- needs node >=22.19.
--
-- Projects that pin an older nodejs in .tool-versions break the asdf shim
-- ("No version is set for command pi"), so launch pi by absolute path out of
-- the home-default install.
local pi_cmd

do
  local tool_versions = vim.fn.expand("~/.tool-versions")

  -- An `if` block, not an early `return`. A bare return inside `do ... end`
  -- leaves the whole chunk, so this file would hand lazy.nvim nil instead of
  -- the spec below, and every plugin here would go missing without a word.
  if vim.fn.filereadable(tool_versions) == 1 then
    for _, line in ipairs(vim.fn.readfile(tool_versions)) do
      local v = line:match("^nodejs%s+(%S+)")

      if v then
        local bin = vim.fn.expand("~/.asdf/installs/nodejs/" .. v .. "/bin")

        if vim.fn.executable(bin .. "/node") == 1 and vim.fn.filereadable(bin .. "/pi") == 1 then
          pi_cmd = { bin .. "/node", bin .. "/pi" }
        end

        break
      end
    end
  end
end

return {

  -- claudecode.nvim in "server only" mode: it runs the WebSocket MCP server
  {
    "coder/claudecode.nvim",
    event = "VeryLazy", -- load eagerly so the server starts and writes the lock file

    opts = {
      terminal = {
        provider = "none", -- no windows/terminals; server + tools only
      },
    },

    keys = {
      -- diff review for edits Claude proposes over the MCP connection
      { "<leader>aA", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: Accept diff" },
      { "<leader>aD", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: Deny diff" },

      -- at-mention context via MCP (separate from sidekick's text prompts)
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: Add current buffer" },
      { "<leader>aS", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: Send selection" },
    },
  },

  -- sidekick provides the CLI UI; tmux mux keeps sessions alive across
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        win = {
          layout = "left", -- AI terminal on the left, editor on the right

          -- Sidekick's default nav action is tmux-unaware: at the window edge
          -- it forwards the key into the terminal instead of handing off to
          -- tmux. With the "left" layout only <c-h> hits that edge case, so
          -- only it needs the vim-tmux-navigator command; the other directions
          -- keep sidekick's defaults (plain window navigation).
          keys = {
            nav_left = { "<c-h>", "TmuxNavigateLeft", desc = "Navigate left (nvim/tmux)" },
          },
        },

        mux = {
          backend = "tmux",
          enabled = true,
        },

        tools = {
          claude = { cmd = { "claude", "--ide" } },
          pi = { cmd = pi_cmd },
        },
      },
    },
  },
}
