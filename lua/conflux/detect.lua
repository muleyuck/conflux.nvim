local M = {}

-- States for the parser state machine
local STATE_IDLE = "IDLE"
local STATE_OURS = "OURS"
local STATE_ANCESTOR = "ANCESTOR"
local STATE_THEIRS = "THEIRS"

--- Scan a buffer for conflict blocks.
--- Malformed or unterminated blocks are silently discarded.
--- @param bufnr number
--- @return table  blocks list (may be empty)
function M.scan(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local blocks = {}
	local state = STATE_IDLE
	local current = {}

	for i, line in ipairs(lines) do
		local lnum = i - 1 -- 0-indexed

		if state == STATE_IDLE then
			if vim.startswith(line, "<<<<<<<") then
				state = STATE_OURS
				current = {
					ours_marker = lnum,
					ours_start = lnum + 1,
				}
			end
		elseif state == STATE_OURS then
			if vim.startswith(line, "|||||||") then
				current.ours_end = lnum
				current.anc_marker = lnum
				current.anc_start = lnum + 1
				state = STATE_ANCESTOR
			elseif vim.startswith(line, "=======") then
				current.ours_end = lnum
				current.sep = lnum
				current.theirs_start = lnum + 1
				state = STATE_THEIRS
			elseif vim.startswith(line, "<<<<<<<") then
				-- Nested/malformed: discard current block, start fresh
				current = { ours_marker = lnum, ours_start = lnum + 1 }
			elseif vim.startswith(line, ">>>>>>>") then
				-- Malformed: discard current block
				current = {}
				state = STATE_IDLE
			end
		elseif state == STATE_ANCESTOR then
			if vim.startswith(line, "=======") then
				current.anc_end = lnum
				current.sep = lnum
				current.theirs_start = lnum + 1
				state = STATE_THEIRS
			elseif vim.startswith(line, "<<<<<<<") then
				-- Malformed: discard current block, start fresh
				current = { ours_marker = lnum, ours_start = lnum + 1 }
				state = STATE_OURS
			elseif vim.startswith(line, ">>>>>>>") then
				-- Malformed: discard current block
				current = {}
				state = STATE_IDLE
			end
		elseif state == STATE_THEIRS then
			if vim.startswith(line, ">>>>>>>") then
				current.theirs_end = lnum
				current.their_marker = lnum
				table.insert(blocks, current)
				current = {}
				state = STATE_IDLE
			elseif vim.startswith(line, "<<<<<<<") then
				-- Malformed: discard current block, start fresh
				current = { ours_marker = lnum, ours_start = lnum + 1 }
				state = STATE_OURS
			elseif vim.startswith(line, "=======") then
				-- Malformed: discard current block
				current = {}
				state = STATE_IDLE
			end
		end
	end

	-- Unterminated block at EOF: silently discard partial block

	return blocks, nil
end

--- Quick check whether a buffer has any conflict markers.
--- @param bufnr number
--- @return boolean
function M.has_conflicts(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for _, line in ipairs(lines) do
		if vim.startswith(line, "<<<<<<<") then
			return true
		end
	end
	return false
end

--- Find the block that contains the given (0-indexed) line number.
--- @param blocks table
--- @param lnum number  0-indexed line number
--- @return table|nil
function M.block_at_line(blocks, lnum)
	for _, block in ipairs(blocks) do
		if lnum >= block.ours_marker and lnum <= block.their_marker then
			return block
		end
	end
	return nil
end

return M
