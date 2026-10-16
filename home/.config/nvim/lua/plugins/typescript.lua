return {
  {
    "dmmulroy/tsc.nvim",
    config = function()
      -- Nova's graph typecheck exceeds Node's default 4 GiB heap.
      local node_options = vim.env.NODE_OPTIONS or ""
      if not node_options:find("%-%-max[-_]old[-_]space[-_]size") then
        vim.env.NODE_OPTIONS = vim.trim(node_options .. " --max-old-space-size=8192")
      end

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
