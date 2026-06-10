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
        mux = {
          backend = "tmux",
          enabled = true,
        },
        tools = {
          claude = { cmd = { "claude", "--ide" } },
        },
      },
    },
  },
}
