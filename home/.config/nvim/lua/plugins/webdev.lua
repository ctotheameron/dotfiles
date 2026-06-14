return {
  -- tailwind-tools.lua
  {
    "luckasRanarison/tailwind-tools.nvim",
    name = "tailwind-tools",
    build = ":UpdateRemotePlugins",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {}, -- your configuration
  },
  {
    "rusagaib/oas-preview.nvim",
    config = function()
      require("oas-preview").setup({
        port = "1111", -- up-to-you
        ui = "swagger", -- "swagger", "redoc", "stoplight"
        expose = false, -- if it true will serve app container to use local network ip with port 80, default are false
        os = "mac", -- "linux", "mac", "win", "wsl" if not set will use default "linux"
      })
    end,
  },
}
