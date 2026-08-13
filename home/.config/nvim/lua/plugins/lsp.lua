-- Diagnostics show the full message as virtual lines, but only under the
-- cursor line. Other lines keep the short inline text.
--
-- Neovim 0.11 added both `current_line` flags, so no autocmd is needed. Older
-- recipes watch CursorMoved and flip virtual_text by hand. Neovim now does
-- that work, and it redraws on every cursor move.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- The full wrapped message, under the cursor line only.
        virtual_lines = { current_line = true },
        -- `false` means "every line except the cursor line". This stops the
        -- inline text and the virtual lines from repeating one message.
        -- LazyVim keeps its spacing, source and prefix through the merge.
        virtual_text = { current_line = false },
      },
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

  {
    -- A second spec entry only registers the toggle. LazyVim does the same for
    -- its Git Signs toggle. The opts function returns nothing, so the opts
    -- above stay as they are.
    "neovim/nvim-lspconfig",
    opts = function()
      -- LazyVim owns the normal virtual_text values, so read them at run time
      -- instead of copying them here.
      local saved_virtual_text

      Snacks.toggle({
        name = "Diagnostic Virtual Lines (all lines)",
        get = function()
          local vl = vim.diagnostic.config().virtual_lines
          return vl ~= false and not (type(vl) == "table" and vl.current_line)
        end,
        set = function(state)
          if state then
            saved_virtual_text = saved_virtual_text or vim.diagnostic.config().virtual_text
            -- Inline text off, because every line now carries its full message.
            vim.diagnostic.config({ virtual_lines = true, virtual_text = false })
          else
            vim.diagnostic.config({
              virtual_lines = { current_line = true },
              virtual_text = saved_virtual_text,
            })
          end
        end,
      }):map("<leader>uv")
    end,
  },
}
