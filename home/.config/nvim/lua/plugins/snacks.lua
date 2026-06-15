return {

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        layout = {
          preset = "ivy",
          -- don't wrap back to the top when scrolling past the last result
          cycle = false,
        },
        -- Custom ivy/vertical layouts with a larger ~50% preview pane
        layouts = {
          ivy = {
            layout = {
              box = "vertical",
              backdrop = true,
              row = -1,
              width = 0,
              height = 0.5,
              border = "top",
              title = " {title} {live} {flags}",
              title_pos = "left",
              { win = "input", height = 1, border = "bottom" },
              {
                box = "horizontal",
                { win = "list", border = "none" },
                {
                  win = "preview",
                  title = "{preview}",
                  width = 0.5,
                  border = "left",
                },
              },
            },
          },
          vertical = {
            layout = {
              backdrop = false,
              width = 0.8,
              min_width = 80,
              height = 0.8,
              min_height = 30,
              box = "vertical",
              border = "rounded",
              title = "{title} {live} {flags}",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
              {
                win = "preview",
                title = "{preview}",
                height = 0.4,
                border = "top",
              },
            },
          },
        },
        matcher = {
          frecency = true,
        },
        actions = {
          -- Send the picker results to the Trouble list. LazyVim only defines
          -- this in its editor.snacks_picker extra (which we don't use), so
          -- register it here. Requires trouble.nvim (shipped by LazyVim).
          trouble_open = function(...)
            return require("trouble.sources.snacks").actions.trouble_open.action(...)
          end,
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
            truncate = 80,
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
