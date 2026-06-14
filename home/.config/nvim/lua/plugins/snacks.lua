return {

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        layout = {
          preset = "ivy",
        },
        matcher = {
          frecency = true,
        },
        win = {
          input = {
            keys = {
              -- close the picker on ESC instead of going to normal mode
              ["<Esc>"] = { "close", mode = { "n", "i" } },
              -- open the selection in trouble
              ["<c-t>"] = {
                "trouble_open",
                mode = { "n", "i" },
              },
            },
          },
        },
        formatters = {
          file = {
            filename_first = true, -- display filename before the file path
          },
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
