-- kulala.nvim: a REST client for `.http` files.
--
-- The format is the JetBrains HTTP Client spec, so the same files open in
-- IntelliJ, WebStorm and VS Code. Environments and secrets live in
-- `http-client.env.json` and `http-client.private.env.json`, beside the files.
--
-- Needs curl, git and tree-sitter-cli, which packages/Brewfile and
-- packages/arch.txt now list. On first run kulala downloads its own
-- kulala-core backend from GitHub releases.
return {
  {
    "mistweaverco/kulala.nvim",

    -- Load before session save and restore, so the hooks register in time.
    event = { "SessionLoadPost", "VimLeavePre" },
    ft = { "http", "rest" },

    -- These entries only wake the plugin. kulala then binds the real action,
    -- because global_keymaps is true below. Without that flag the keys load
    -- kulala and then do nothing at all.
    keys = {
      { "<leader>R", "", desc = "+rest" },
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Re", desc = "Select environment" },
      { "<leader>Ru", desc = "Manage auth config" },
      { "<leader>Rb", desc = "Open scratchpad" },
      { "<leader>Rf", desc = "Find request" },
      { "<leader>Ri", desc = "Inspect current request" },
    },

    opts = {
      -- Bind kulala's own keymap set under <leader>R. Off by default.
      global_keymaps = true,
      global_keymaps_prefix = "<leader>R",

      -- Show the response beside the request, not below it.
      display_mode = "split",
      split_direction = "vertical",

      -- Open the body first. Headers are one keypress away.
      default_view = "body",

      -- Keep the environment choice per project, so a switch to production
      -- does not follow you into another repo.
      environment_scope = "b",

      -- Read the environment that the VS Code REST Client extension uses, so
      -- a teammate's settings still work here.
      vscode_rest_client_environmentvars = true,
    },
  },
}
