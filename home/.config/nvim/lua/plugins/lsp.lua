return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = true,
        exclude = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
      },
      servers = {
        lua_ls = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
        marksman = {},
        ruby_lsp = {
          root_markers = { "Gemfile", ".git" },
        },
        sorbet = {},
        rubocop = {
          -- See: https://docs.rubocop.org/rubocop/usage/lsp.html
          cmd = { "bundle", "exec", "rubocop", "--lsp" },
          root_markers = { "Gemfile", ".git" },
          enabled = true,
        },
        sqlls = {},
        terraformls = {},
        yamlls = {},
      },
    },
  },
}
