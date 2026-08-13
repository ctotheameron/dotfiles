-- Diagnostics show the full message as virtual lines, but only under the
-- cursor line. Other lines keep the short inline text.
--
-- Neovim 0.11 added both `current_line` flags, so no autocmd is needed. Older
-- recipes watch CursorMoved and flip virtual_text by hand. Neovim now does
-- that work, and it redraws on every cursor move.

-- Neovim never wraps virtual lines. It sets `virt_lines_overflow = "scroll"`,
-- so one long message runs far off the right edge. But the renderer splits the
-- message on newline characters, and it draws one virtual line for each part.
-- So a `format` function can do the wrapping.
local WIDTH = 80

-- Neovim draws a `└──── ` gutter before the message, and indents the block to
-- the column of the diagnostic. Both eat into the space left for text.
local GUTTER = 6

-- A deeply indented diagnostic leaves very little room. Below this floor the
-- text becomes a narrow ribbon, so the block is allowed to pass WIDTH instead.
-- Set this to 1 to hold the 80 column limit at every indent.
local MIN_WIDTH = 30

--- Greedy word wrap. A word that is wider than the limit is cut, so no line
--- ever passes the limit. The cut counts characters, so it keeps multi-byte
--- characters whole.
---@param text string
---@param width integer
---@return string # the parts, joined with newline characters
local function wrap(text, width)
  local out = {}

  for _, paragraph in ipairs(vim.split(text, "\n", { plain = true })) do
    local line = ""

    local function flush()
      if line ~= "" then
        table.insert(out, line)
        line = ""
      end
    end

    for word in paragraph:gmatch("%S+") do
      while vim.fn.strdisplaywidth(word) > width do
        flush()
        table.insert(out, vim.fn.strcharpart(word, 0, width))
        word = vim.fn.strcharpart(word, width)
      end

      if line == "" then
        line = word
      elseif vim.fn.strdisplaywidth(line .. " " .. word) <= width then
        line = line .. " " .. word
      else
        flush()
        line = word
      end
    end

    flush()
  end

  return table.concat(out, "\n")
end

--- How far Neovim indents the block, which is the width of the buffer text in
--- front of the diagnostic.
---@param diagnostic vim.Diagnostic
---@return integer
local function indent_of(diagnostic)
  local buf = diagnostic.bufnr
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return 0
  end

  local line = vim.api.nvim_buf_get_lines(buf, diagnostic.lnum, diagnostic.lnum + 1, false)[1]
  if not line then
    return 0
  end

  return vim.fn.strdisplaywidth(line:sub(1, diagnostic.col))
end

---@param diagnostic vim.Diagnostic
---@return string
local function format_virtual_line(diagnostic)
  -- Neovim's own formatter adds the code, so keep doing that.
  local message = diagnostic.code and string.format("%s: %s", diagnostic.code, diagnostic.message)
    or diagnostic.message

  return wrap(message, math.max(MIN_WIDTH, WIDTH - indent_of(diagnostic) - GUTTER))
end

-- Both modes wrap. Without `current_line`, virtual lines show on every line.
local CURSOR_LINE = { current_line = true, format = format_virtual_line }
local EVERY_LINE = { format = format_virtual_line }

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- The full wrapped message, under the cursor line only.
        virtual_lines = CURSOR_LINE,
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
            vim.diagnostic.config({ virtual_lines = EVERY_LINE, virtual_text = false })
          else
            vim.diagnostic.config({
              virtual_lines = CURSOR_LINE,
              virtual_text = saved_virtual_text,
            })
          end
        end,
      }):map("<leader>uv")
    end,
  },
}
