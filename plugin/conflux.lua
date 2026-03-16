if vim.g.loaded_conflux then
	return
end
vim.g.loaded_conflux = true

local augroup = vim.api.nvim_create_augroup("Conflux", { clear = true })

-- Detect and attach on buffer read/write
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
	group = augroup,
	callback = function(ev)
		local ok, conflux = pcall(require, "conflux")
		if ok and conflux._is_setup then
			conflux.try_attach(ev.buf)
		end
	end,
})

-- Re-detect on in-memory text changes (e.g. undo restoring conflict markers)
vim.api.nvim_create_autocmd("TextChanged", {
	group = augroup,
	callback = function(ev)
		local ok, conflux = pcall(require, "conflux")
		if ok and conflux._is_setup then
			conflux.try_attach(ev.buf)
		end
	end,
})

-- Redefine highlights after colorscheme change
vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup,
	callback = function()
		local ok, hl = pcall(require, "conflux.highlight")
		if not ok or not hl._ns_id then
			return
		end
		hl._define_highlights()
		local ok2, conflux = pcall(require, "conflux")
		if ok2 then
			for bufnr, state in pairs(conflux._attached) do
				hl.apply(bufnr, state.blocks)
			end
		end
	end,
})

-- Helper to build command callbacks
local function make_cmd(action)
	return function()
		local ok, conflux = pcall(require, "conflux")
		if not ok then
			vim.notify("conflux: plugin not loaded", vim.log.levels.ERROR)
			return
		end
		local bufnr = vim.api.nvim_get_current_buf()
		local blocks = conflux.get_blocks(bufnr)
		if not blocks then
			vim.notify("conflux: no conflicts tracked in this buffer", vim.log.levels.WARN)
			return
		end
		local new_blocks = require("conflux.commands").resolve(bufnr, blocks, action)
		conflux.set_blocks(bufnr, new_blocks or {})
	end
end

vim.api.nvim_create_user_command("ConfluxOurs", make_cmd("ours"), { desc = "Keep ours (current) changes" })
vim.api.nvim_create_user_command("ConfluxTheirs", make_cmd("theirs"), { desc = "Keep theirs (incoming) changes" })
vim.api.nvim_create_user_command("ConfluxBoth", make_cmd("both"), { desc = "Keep both changes (ours first)" })
vim.api.nvim_create_user_command("ConfluxNone", make_cmd("none"), { desc = "Discard both changes" })
