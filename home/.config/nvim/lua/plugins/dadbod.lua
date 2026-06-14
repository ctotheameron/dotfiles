local table_helpers = {
  postgresql = {
    List = [[
SELECT
  *
FROM
  "{table}"
LIMIT 200
]],

    Columns = [[
SELECT
  *
FROM
  information_schema.columns
WHERE
  table_name = '{table}' AND
  table_schema = 'public'
]],

    ["Primary Keys"] = [[
SELECT
  *
FROM
  information_schema.table_constraints
WHERE
  constraint_type = 'PRIMARY KEY' AND
  table_schema = 'public' AND
  table_name = '{table}'
]],

    Indexes = [[
SELECT
  *
FROM
  pg_indexes
WHERE
  tablename = '{table}' AND
  schemaname = 'public'
]],

    ["Find by ID"] = [[
SELECT
  *
FROM
  "{table}"
WHERE
  id = :id
]],

    References = [[
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.update_rule,
  rc.delete_rule
FROM
  information_schema.table_constraints AS tc
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
  JOIN information_schema.referential_constraints as rc
    ON tc.constraint_name = rc.constraint_name
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE
  constraint_type = 'FOREIGN KEY' AND
  ccu.table_name = '{table}' AND
  tc.table_schema = 'public'
]],

    ["Foreign Keys"] = [[
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.update_rule,
  rc.delete_rule
FROM
  information_schema.table_constraints AS tc
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
  JOIN information_schema.referential_constraints as rc
    ON tc.constraint_name = rc.constraint_name
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE
  constraint_type = 'FOREIGN KEY' AND
  tc.table_name = '{table}' AND
  tc.table_schema = 'public'
]],
  },
}

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = "vim-dadbod",
    init = function()
      local data_path = vim.fn.stdpath("data")

      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_use_nvim_notify = true
      vim.g.db_ui_table_helpers = table_helpers

      -- NOTE: The default behavior of auto-execution of queries on save is disabled
      -- this is useful when you have a big query that you don't want to run every time
      -- you save the file running those queries can crash neovim to run use the
      -- default keymap: <leader>S
      vim.g.db_ui_execute_on_save = false
    end,
  },
  {
    "davesavic/dadbod-ui-yank",
    dependencies = { "kristijanhusak/vim-dadbod-ui" },
    config = function()
      require("dadbod-ui-yank").setup()
    end,
  },
}
