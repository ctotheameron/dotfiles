-- Run from the repo root: nvim --headless -u NONE -l scripts/test-nvim-typescript.lua
package.loaded.tsc = { setup = function() end }
local configure = dofile("home/.config/nvim/lua/plugins/typescript.lua")[1].config

for _, case in ipairs({
	{ input = false, expected = "--max-old-space-size=8192" },
	{ input = "", expected = "--max-old-space-size=8192" },
	{ input = "--enable-source-maps", expected = "--enable-source-maps --max-old-space-size=8192" },
	{ input = "--max-old-space-size=16384", expected = "--max-old-space-size=16384" },
	{ input = "--max_old_space_size=6144", expected = "--max_old_space_size=6144" },
}) do
	vim.env.NODE_OPTIONS = case.input or nil
	configure()
	assert(vim.env.NODE_OPTIONS == case.expected, vim.inspect(case))
	configure()
	assert(vim.env.NODE_OPTIONS == case.expected, "configuration is not idempotent")
end

print("PASS: Node heap default, existing options, explicit limits, and reload idempotency")
vim.cmd("qa!")
