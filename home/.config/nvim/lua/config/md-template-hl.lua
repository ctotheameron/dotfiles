-- Highlight markdown`...` tagged template bodies as real markdown.
--
-- Native tree-sitter injection can't strip indentation, so a template body
-- indented 4+ spaces parses as one markdown indented_code_block (flat color,
-- no headings/bold). Instead we dedent the text ourselves, parse the string
-- with the markdown parser, and map the highlight captures back onto the
-- buffer as extmarks.

local M = {}

local ns = vim.api.nvim_create_namespace("md_template_hl")
local queries = {} ---@type table<string, vim.treesitter.Query|false>

local function get_query(lang)
  if queries[lang] == nil then
    local ok, q = pcall(
      vim.treesitter.query.parse,
      lang,
      [[
        (call_expression
          function: (identifier) @_tag (#eq? @_tag "markdown")
          arguments: (template_string (string_fragment) @content))
      ]]
    )
    queries[lang] = ok and q or false
  end
  return queries[lang] or nil
end

---Dedent one string_fragment, parse it as markdown (incl. markdown_inline
---injections), and re-apply the highlights at the original positions.
local function highlight_fragment(buf, node)
  local srow, scol, erow, ecol = node:range()
  local lines = vim.api.nvim_buf_get_lines(buf, srow, erow + 1, false)
  if #lines == 0 then
    return
  end
  if erow == srow then
    lines[1] = lines[1]:sub(scol + 1, ecol)
  else
    lines[1] = lines[1]:sub(scol + 1)
    lines[#lines] = lines[#lines]:sub(1, ecol)
  end

  -- common indent of non-blank lines (first line starts mid-line, skip it)
  local indent = math.huge
  for i = 2, #lines do
    if lines[i]:find("%S") then
      indent = math.min(indent, #lines[i]:match("^[ \t]*"))
    end
  end
  if indent == math.huge then
    indent = 0
  end

  local dedented = { lines[1] }
  for i = 2, #lines do
    dedented[i] = lines[i]:sub(indent + 1)
  end
  local text = table.concat(dedented, "\n")

  local ok, parser = pcall(vim.treesitter.get_string_parser, text, "markdown")
  if not ok then
    return
  end
  parser:parse(true)
  parser:for_each_tree(function(tree, ltree)
    local lang = ltree:lang()
    local hq = vim.treesitter.query.get(lang, "highlights")
    if not hq then
      return
    end
    for id, cnode, meta in hq:iter_captures(tree:root(), text) do
      local name = hq.captures[id]
      if name ~= "spell" and name ~= "nospell" then
        local csrow, cscol, cerow, cecol = cnode:range()
        local prio = tonumber(meta.priority or (meta[id] or {}).priority) or 100
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, srow + csrow, cscol + (csrow == 0 and scol or indent), {
          end_row = srow + cerow,
          end_col = cecol + (cerow == 0 and scol or indent),
          hl_group = "@" .. name .. "." .. lang,
          priority = prio + 10, -- above the host @string highlight (100)
          strict = false,
        })
      end
    end
  end)
end

local function apply(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok or not parser then
    return
  end
  local query = lang and get_query(lang)
  if not query then
    return
  end
  local tree = parser:parse()[1]
  for id, node in query:iter_captures(tree:root(), buf) do
    if query.captures[id] == "content" then
      highlight_fragment(buf, node)
    end
  end
end

local function attach(buf)
  if vim.b[buf].md_template_hl then
    apply(buf)
    return
  end
  vim.b[buf].md_template_hl = true
  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    buffer = buf,
    callback = function()
      apply(buf)
    end,
  })
  apply(buf)
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "typescriptreact" },
    group = vim.api.nvim_create_augroup("md_template_hl", { clear = true }),
    callback = function(ev)
      attach(ev.buf)
    end,
  })
  -- this module loads on VeryLazy, after the first file's FileType already fired
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local ft = vim.bo[buf].filetype
    if ft == "typescript" or ft == "typescriptreact" then
      attach(buf)
    end
  end
end

return M
