return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "graphql" } },
  },

  -- Rainbow brackets: color-match nested delimiters
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "LazyFile",
  },
}
