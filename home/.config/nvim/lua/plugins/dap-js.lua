-- JavaScript/TypeScript debugging: attach to a running Node `--inspect` process.
--
-- The `pwa-node` adapter and `js-debug-adapter` binary come from LazyVim's
-- typescript extra; this adds a generic *port-based* attach config (the
-- built-in one only offers a PID picker) and pins the adapter in Mason.
--
-- Project-specific named configs (e.g. nova app/graph on fixed ports) live in
-- that project's own `.lazy.lua`, loaded automatically by lazy.nvim.
return {
  "mfussenegger/nvim-dap",
  optional = true,
  dependencies = {
    {
      "mason-org/mason.nvim",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        if not vim.tbl_contains(opts.ensure_installed, "js-debug-adapter") then
          table.insert(opts.ensure_installed, "js-debug-adapter")
        end
      end,
    },
  },
  -- Runs after LazyVim's typescript extra has set up the base configs (user
  -- specs load last), so we append rather than overwrite.
  opts = function()
    local dap = require("dap")
    local name = "Attach to Node (--inspect port)"
    local function port_attach()
      return {
        type = "pwa-node",
        request = "attach",
        name = name,
        port = function()
          return tonumber(vim.fn.input("Inspect port: ", "9229"))
        end,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
        restart = true, -- reconnect when `node --watch` restarts the process
      }
    end
    for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
      dap.configurations[ft] = dap.configurations[ft] or {}
      local exists = false
      for _, c in ipairs(dap.configurations[ft]) do
        if c.name == name then
          exists = true
          break
        end
      end
      if not exists then
        table.insert(dap.configurations[ft], port_attach())
      end
    end
  end,
}
