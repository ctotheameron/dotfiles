return {
  {
    -- Fork with a fix for the Biome 2.x JSON reporter format.
    -- Upstream reads fields that Biome 2.0 removed and crashes.
    -- Revert to AlexBeauchemin/biome-lint.nvim when upstream merges the fix.
    "ctotheameron/biome-lint.nvim",
    branch = "fix/biome-2-json-format",

    config = function()
      require("biome-lint").setup({
        severity = "error", -- "error", "warn", "info". Default is "error"
      })
    end,
  },
}
