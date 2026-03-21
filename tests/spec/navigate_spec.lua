local navigate = require('conflux.navigate')
local detect = require('conflux.detect')

-- Two-conflict fixture for next/prev tests.
-- Row layout:
--   row 1  (0-idx 0):  'before'
--   row 2  (0-idx 1):  '<<<<<<< HEAD'   <- block[1].ours_marker = 1
--   row 3  (0-idx 2):  'ours1'
--   row 4  (0-idx 3):  '======='
--   row 5  (0-idx 4):  'theirs1'
--   row 6  (0-idx 5):  '>>>>>>> branch'
--   row 7  (0-idx 6):  'between'
--   row 8  (0-idx 7):  '<<<<<<< HEAD'   <- block[2].ours_marker = 7
--   row 9  (0-idx 8):  'ours2'
--   row 10 (0-idx 9):  '======='
--   row 11 (0-idx 10): 'theirs2'
--   row 12 (0-idx 11): '>>>>>>> branch'
--   row 13 (0-idx 12): 'after'
local TWO_CONFLICT_LINES = {
  'before',
  '<<<<<<< HEAD',
  'ours1',
  '=======',
  'theirs1',
  '>>>>>>> branch',
  'between',
  '<<<<<<< HEAD',
  'ours2',
  '=======',
  'theirs2',
  '>>>>>>> branch',
  'after',
}

-- Single-conflict fixture.
-- Row layout:
--   row 1 (0-idx 0): 'before'
--   row 2 (0-idx 1): '<<<<<<< HEAD'   <- block[1].ours_marker = 1
--   row 3 (0-idx 2): 'ours'
--   row 4 (0-idx 3): '======='
--   row 5 (0-idx 4): 'theirs'
--   row 6 (0-idx 5): '>>>>>>> branch'
--   row 7 (0-idx 6): 'after'
local SINGLE_CONFLICT_LINES = {
  'before',
  '<<<<<<< HEAD',
  'ours',
  '=======',
  'theirs',
  '>>>>>>> branch',
  'after',
}

-- ─────────────────────────────────────────────
-- navigate.next — two-block buffer
-- ─────────────────────────────────────────────
describe('navigate.next / two blocks', function()
  before_all(function()
    require('conflux').setup({})
  end)

  local bufnr

  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, TWO_CONFLICT_LINES)
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, bufnr)
  end)

  after_each(function()
    pcall(vim.cmd, 'close')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it('jumps to first block when cursor is before it', function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- row 1: 'before'
    local blocks = detect.scan(bufnr)
    navigate.next(bufnr, blocks)
    eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0))
  end)

  it('jumps to second block when cursor is between the two', function()
    vim.api.nvim_win_set_cursor(0, { 7, 0 }) -- row 7: 'between'
    local blocks = detect.scan(bufnr)
    navigate.next(bufnr, blocks)
    eq({ 8, 0 }, vim.api.nvim_win_get_cursor(0))
  end)

  it('jumps to second block when cursor is on their_marker of first block', function()
    vim.api.nvim_win_set_cursor(0, { 6, 0 }) -- row 6: '>>>>>>> branch' (their_marker of block 1)
    local blocks = detect.scan(bufnr)
    navigate.next(bufnr, blocks)
    eq({ 8, 0 }, vim.api.nvim_win_get_cursor(0)) -- their_marker is inside block: jumps to block 2
  end)

  it('goes to last block marker when cursor is inside last block body', function()
    vim.api.nvim_win_set_cursor(0, { 9, 0 }) -- row 9: 'ours2' (inside block 2)
    local blocks = detect.scan(bufnr)
    navigate.next(bufnr, blocks)
    eq({ 8, 0 }, vim.api.nvim_win_get_cursor(0)) -- no next: goes to last block marker
  end)

  it('goes to last block when cursor is after all blocks', function()
    vim.api.nvim_win_set_cursor(0, { 13, 0 }) -- row 13: 'after'
    local blocks = detect.scan(bufnr)
    navigate.next(bufnr, blocks)
    eq({ 8, 0 }, vim.api.nvim_win_get_cursor(0)) -- no next: goes to last block
  end)

  it('jumps to second block when cursor is inside first block body', function()
    vim.api.nvim_win_set_cursor(0, { 3, 0 }) -- row 3: 'ours1' (inside block 1)
    local blocks = detect.scan(bufnr)
    navigate.next(bufnr, blocks)
    eq({ 8, 0 }, vim.api.nvim_win_get_cursor(0)) -- jumps to block 2
  end)

  it('does nothing when blocks is empty', function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    navigate.next(bufnr, {})
    eq({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
  end)
end)

-- ─────────────────────────────────────────────
-- navigate.prev — two-block buffer
-- ─────────────────────────────────────────────
describe('navigate.prev / two blocks', function()
  before_all(function()
    require('conflux').setup({})
  end)

  local bufnr

  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, TWO_CONFLICT_LINES)
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, bufnr)
  end)

  after_each(function()
    pcall(vim.cmd, 'close')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it('jumps to second block when cursor is after it', function()
    vim.api.nvim_win_set_cursor(0, { 13, 0 }) -- row 13: 'after'
    local blocks = detect.scan(bufnr)
    navigate.prev(bufnr, blocks)
    eq({ 8, 0 }, vim.api.nvim_win_get_cursor(0))
  end)

  it('jumps to first block when cursor is between the two', function()
    vim.api.nvim_win_set_cursor(0, { 7, 0 }) -- row 7: 'between'
    local blocks = detect.scan(bufnr)
    navigate.prev(bufnr, blocks)
    eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0))
  end)

  it('jumps to first block when cursor is on their_marker of second block', function()
    vim.api.nvim_win_set_cursor(0, { 12, 0 }) -- row 12: '>>>>>>> branch' (their_marker of block 2)
    local blocks = detect.scan(bufnr)
    navigate.prev(bufnr, blocks)
    eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0)) -- their_marker is inside block: jumps to block 1
  end)

  it('goes to first block when cursor is before all blocks', function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- row 1: 'before'
    local blocks = detect.scan(bufnr)
    navigate.prev(bufnr, blocks)
    eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0)) -- no prev: goes to first block
  end)

  it('goes to first block marker when cursor is inside first block body', function()
    vim.api.nvim_win_set_cursor(0, { 3, 0 }) -- row 3: 'ours1' (inside block 1, no prev block)
    local blocks = detect.scan(bufnr)
    navigate.prev(bufnr, blocks)
    eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0)) -- no prev: goes to first block marker
  end)

  it('jumps to first block when cursor is inside second block body', function()
    vim.api.nvim_win_set_cursor(0, { 9, 0 }) -- row 9: 'ours2' (inside block 2)
    local blocks = detect.scan(bufnr)
    navigate.prev(bufnr, blocks)
    eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0)) -- jumps to block 1
  end)

  it('does nothing when blocks is empty', function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    navigate.prev(bufnr, {})
    eq({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
  end)
end)

-- ─────────────────────────────────────────────
-- navigate — single-block buffer
-- ─────────────────────────────────────────────
describe('navigate / single block', function()
  before_all(function()
    require('conflux').setup({})
  end)

  local bufnr

  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, SINGLE_CONFLICT_LINES)
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, bufnr)
  end)

  after_each(function()
    pcall(vim.cmd, 'close')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it('next wraps silently to the only block when cursor is on its marker', function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 }) -- on the <<<<<<< marker
    local blocks = detect.scan(bufnr)
    navigate.next(bufnr, blocks)
    eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0)) -- same position, no-op visually
  end)

  it('prev wraps silently to the only block when cursor is on its marker', function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 }) -- on the <<<<<<< marker
    local blocks = detect.scan(bufnr)
    navigate.prev(bufnr, blocks)
    eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0)) -- same position, no-op visually
  end)
end)
