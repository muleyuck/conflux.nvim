local commands = require('conflux.commands')
local detect = require('conflux.detect')

describe('commands.resolve', function()
  -- Initialize config and highlight namespace once.
  -- highlight.apply() silently no-ops without this, but setup() mirrors
  -- real-world usage and prevents surprises if future code paths use config.
  before_all(function()
    require('conflux').setup({})
  end)

  -- Conflict buffer content:
  --   line 1 (0-idx 0): 'before'
  --   line 2 (0-idx 1): '<<<<<<< HEAD'     <- ours_marker = 1
  --   line 3 (0-idx 2): 'ours content'
  --   line 4 (0-idx 3): '======='
  --   line 5 (0-idx 4): 'theirs content'
  --   line 6 (0-idx 5): '>>>>>>> branch'   <- their_marker = 5
  --   line 7 (0-idx 6): 'after'
  local CONFLICT_LINES = {
    'before',
    '<<<<<<< HEAD',
    'ours content',
    '=======',
    'theirs content',
    '>>>>>>> branch',
    'after',
  }

  local bufnr

  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, CONFLICT_LINES)
    -- Open buffer in a split so bufwinid(bufnr) returns a real window ID.
    -- Without this, bufwinid returns -1 and resolve() falls back to window 0 (wrong buffer).
    vim.cmd('split')
    vim.api.nvim_win_set_buf(0, bufnr)
  end)

  after_each(function()
    pcall(vim.cmd, 'close') -- pcall: guards against close failing if test errored early
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it('ours / keeps ours content, removes markers and theirs', function()
    local blocks = detect.scan(bufnr)
    vim.api.nvim_win_set_cursor(0, { 3, 0 }) -- row 3 = inside ours block (1-indexed)
    commands.resolve(bufnr, blocks, 'ours')
    eq({ 'before', 'ours content', 'after' }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)

  it('theirs / keeps theirs content, removes markers and ours', function()
    local blocks = detect.scan(bufnr)
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    commands.resolve(bufnr, blocks, 'theirs')
    eq({ 'before', 'theirs content', 'after' }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)

  it('both / concatenates ours then theirs, removes markers', function()
    local blocks = detect.scan(bufnr)
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    commands.resolve(bufnr, blocks, 'both')
    eq(
      { 'before', 'ours content', 'theirs content', 'after' },
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    )
  end)

  it('none / removes entire conflict block including markers', function()
    local blocks = detect.scan(bufnr)
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    commands.resolve(bufnr, blocks, 'none')
    eq({ 'before', 'after' }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
end)
