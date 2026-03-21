local M = {}

--- Return the index of the block that contains cursor_row (1-indexed), or nil.
--- A block spans from its ours_marker line to its their_marker line (inclusive, 1-indexed).
local function current_block_index(cursor_row, blocks)
  for i, block in ipairs(blocks) do
    if cursor_row >= block.ours_marker + 1 and cursor_row <= block.their_marker + 1 then
      return i
    end
  end
  return nil
end

--- Jump to the next conflict block after the cursor.
--- If the cursor is inside a conflict block, jumps to the one after it.
--- If the cursor is between blocks, jumps to the nearest next block.
--- Goes to the last block when there is no next conflict.
--- Notifies when there is no next conflict and #blocks >= 2.
--- @param bufnr number
--- @param blocks table  pre-scanned conflict blocks (non-nil, may be empty)
function M.next(bufnr, blocks)
  if #blocks == 0 then
    return
  end

  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    winid = 0
  end
  local cursor_row = vim.api.nvim_win_get_cursor(winid)[1] -- 1-indexed

  local target
  local cur_idx = current_block_index(cursor_row, blocks)
  if cur_idx then
    -- Cursor is inside block cur_idx: jump to the next one.
    if cur_idx < #blocks then
      target = blocks[cur_idx + 1]
    end
  else
    -- Cursor is between blocks: find the first block strictly after cursor.
    for _, block in ipairs(blocks) do
      if block.ours_marker + 1 > cursor_row then
        target = block
        break
      end
    end
  end

  if target then
    vim.api.nvim_win_set_cursor(winid, { target.ours_marker + 1, 0 })
  else
    -- No next conflict: go to the last conflict.
    vim.api.nvim_win_set_cursor(winid, { blocks[#blocks].ours_marker + 1, 0 })
    if #blocks >= 2 then
      vim.notify(
        string.format('conflux: wrapped to last conflict (%d/%d)', #blocks, #blocks),
        vim.log.levels.INFO
      )
    end
  end
end

--- Jump to the previous conflict block before the cursor.
--- If the cursor is inside a conflict block, jumps to the one before it.
--- If the cursor is between blocks, jumps to the nearest previous block.
--- Goes to the first block when there is no previous conflict.
--- Notifies when there is no previous conflict and #blocks >= 2.
--- @param bufnr number
--- @param blocks table  pre-scanned conflict blocks (non-nil, may be empty)
function M.prev(bufnr, blocks)
  if #blocks == 0 then
    return
  end

  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    winid = 0
  end
  local cursor_row = vim.api.nvim_win_get_cursor(winid)[1] -- 1-indexed

  local target
  local cur_idx = current_block_index(cursor_row, blocks)
  if cur_idx then
    -- Cursor is inside block cur_idx: jump to the previous one.
    if cur_idx > 1 then
      target = blocks[cur_idx - 1]
    end
  else
    -- Cursor is between blocks: find the last block strictly before cursor.
    for i = #blocks, 1, -1 do
      local block = blocks[i]
      if block.their_marker + 1 < cursor_row then
        target = block
        break
      end
    end
  end

  if target then
    vim.api.nvim_win_set_cursor(winid, { target.ours_marker + 1, 0 })
  else
    -- No prev conflict: go to the first conflict.
    vim.api.nvim_win_set_cursor(winid, { blocks[1].ours_marker + 1, 0 })
    if #blocks >= 2 then
      vim.notify(
        string.format('conflux: wrapped to first conflict (1/%d)', #blocks),
        vim.log.levels.INFO
      )
    end
  end
end

return M
