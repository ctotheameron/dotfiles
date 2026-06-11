return {
  {
    "dmmulroy/tsc.nvim",
    config = function()
      require("tsc").setup({
        auto_open_qflist = true,
        use_trouble_qflist = true,
      })
    end,
  },
}
