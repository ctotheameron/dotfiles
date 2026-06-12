return {
  {
    "dmmulroy/tsc.nvim",
    config = function()
      require("tsc").setup({
        auto_open_qflist = true,
        use_trouble_qflist = true,
        -- The progress spinner animates via repeated vim.notify calls that
        -- rely on nvim-notify's in-place replace, which noice's mini view
        -- doesn't support -- each frame stacked as a new popup
        enable_progress_notifications = false,
      })
    end,
  },
}
