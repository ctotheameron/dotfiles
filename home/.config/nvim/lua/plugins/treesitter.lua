return {
  {
    "nvim-treesitter/nvim-treesitter",

    opts = { ensure_installed = { "graphql", "gritql" } },

    init = function()
      -- Biome plugins are written in GritQL. Neovim detects no filetype for
      -- `.grit`, so map it here. The filetype matches the parser name below,
      -- so vim.treesitter.language.register is not needed.
      vim.filetype.add({ extension = { grit = "gritql" } })

      -- nvim-treesitter ships no gritql parser, so add Biome's grammar.
      -- Biome took the grammar over from getgrit, and the old URL only
      -- redirects. `queries` copies highlights.scm and injections.scm from the
      -- same commit, so no query files need to live in this repo.
      --
      -- The autocmd is the documented hook: get_available() fires
      -- `User TSUpdate` just before it reads the parser list. A plain
      -- assignment at startup runs too late, and :TSInstall then reports
      -- "skipping unsupported language".
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        group = vim.api.nvim_create_augroup("gritql_parser", { clear = true }),
        callback = function()
          require("nvim-treesitter.parsers").gritql = {
            install_info = {
              url = "https://github.com/biomejs/tree-sitter-gritql",
              revision = "7e3e1a74e82c7a5caac1e58884067289f0ebae51",
              queries = "queries",
            },
          }
        end,
      })
    end,
  },
}
