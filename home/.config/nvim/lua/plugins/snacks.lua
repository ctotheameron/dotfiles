return {

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        layout = {
          preset = "ivy",
        },
      },
      styles = {
        -- <leader>gg lazygit float fills the whole editor (0 = full size)
        lazygit = {
          width = 0,
          height = 0,
        },
      },
    },
  },
}
