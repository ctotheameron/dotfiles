return {
  {
    "catppuccin/nvim",

    lazy = true,
    name = "catppuccin",

    opts = {
      transparent_background = true,
      flavour = "mocha",
      float = {
        transparent = true,
        solid = false,
      },
      highlight_overrides = {
        --@param cp palette
        all = function(cp)
          return {
            ["@tag.attribute.tsx"] = { fg = cp.lavender, style = clear },
            ["@tag.delimiter.tsx"] = { fg = cp.mauve, style = clear },
            ["@tag.tsx"] = { fg = cp.mauve, style = clear },
          }
        end,
      },
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        snacks = { enabled = true },
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
