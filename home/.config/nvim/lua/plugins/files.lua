return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = false },
    },
  },
  {
    "nvim-mini/mini.files",
    opts = {
      windows = {
        max_number = 3,
        width_preview = 80,
      },
    },
    keys = {
      {
        "-",
        function()
          require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = "Open mini.files (Current File Directory)",
      },
    },
  },
}
