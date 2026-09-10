return {
  {
    "AlexBeauchemin/biome-lint.nvim",

    config = function()
      require("biome-lint").setup({
        severity = "error", -- "error", "warn", "info". Default is "error"
      })
    end,
  },
}
