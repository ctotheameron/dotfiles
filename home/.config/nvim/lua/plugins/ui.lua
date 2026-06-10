return {
  -- Disabled plugins
  { "akinsho/bufferline.nvim", enabled = false },

  -- Keep the noice cmdline popup, but render notifications as plain text
  -- in the bottom right (mini view) instead of popups
  {
    "folke/noice.nvim",
    opts = {
      messages = {
        view = "mini",
        view_error = "mini",
        view_warn = "mini",
      },
      notify = { view = "mini" },
      lsp = {
        message = { view = "mini" },
      },
    },
  },

  -- Let noice's mini view handle notifications instead of snacks popups
  {
    "folke/snacks.nvim",
    opts = {
      notifier = { enabled = false },
    },
  },
}
