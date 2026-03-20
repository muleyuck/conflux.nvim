local M = {}

--- Get the replacement lines for a given resolution type.
--- @param bufnr number
--- @param block table
--- @param resolution string  'ours'|'theirs'|'both'|'none'
--- @return string[]
function M._get_replacement(bufnr, block, resolution)
	local function get_lines(start, stop)
		if start >= stop then
			return {}
		end
		return vim.api.nvim_buf_get_lines(bufnr, start, stop, false)
	end

	if resolution == "ours" then
		return get_lines(block.ours_start, block.ours_end)
	elseif resolution == "theirs" then
		return get_lines(block.theirs_start, block.theirs_end)
	elseif resolution == "both" then
		local ours = get_lines(block.ours_start, block.ours_end)
		local theirs = get_lines(block.theirs_start, block.theirs_end)
		local result = {}
		vim.list_extend(result, ours)
		vim.list_extend(result, theirs)
		return result
	elseif resolution == "none" then
		return {}
	else
		error("conflux: unknown resolution type: " .. tostring(resolution))
	end
end

--- Re-scan the buffer and re-apply highlights. Returns new blocks.
--- @param bufnr number
--- @return table
function M._refresh(bufnr)
	local detect = require("conflux.detect")
	local highlight = require("conflux.highlight")
	local blocks, err = detect.scan(bufnr)
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return {}
	end
	blocks = blocks or {}
	highlight.apply(bufnr, blocks)
	return blocks
end

--- Resolve the conflict block under the cursor.
--- @param bufnr number
--- @param blocks table
--- @param resolution string  'ours'|'theirs'|'both'|'none'
--- @return table  updated blocks after resolution
function M.resolve(bufnr, blocks, resolution)
	if not vim.bo[bufnr].modifiable then
		vim.notify("conflux: buffer is read-only", vim.log.levels.WARN)
		return blocks
	end

	local winid = vim.fn.bufwinid(bufnr)
	if winid == -1 then winid = 0 end
	local cursor = vim.api.nvim_win_get_cursor(winid)
	local lnum = cursor[1] - 1 -- convert to 0-indexed

	local detect = require("conflux.detect")
	local block = detect.block_at_line(blocks, lnum)

	if not block then
		vim.notify("conflux: cursor is not inside a conflict block", vim.log.levels.WARN)
		return blocks
	end

	local replacement = M._get_replacement(bufnr, block, resolution)

	local ok, err = pcall(function()
		vim.api.nvim_buf_set_lines(bufnr, block.ours_marker, block.their_marker + 1, false, replacement)
	end)

	if not ok then
		vim.notify("conflux: failed to apply resolution: " .. tostring(err), vim.log.levels.ERROR)
		return blocks
	end

	-- Restore cursor to the start of where the block was
	local target_row = block.ours_marker + 1 -- nvim_win_set_cursor is 1-indexed
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	if target_row > line_count then
		target_row = line_count
	end
	if target_row < 1 then
		target_row = 1
	end
	vim.api.nvim_win_set_cursor(winid, { target_row, 0 })

	-- Re-scan and re-highlight after the edit
	return M._refresh(bufnr)
end

return M
