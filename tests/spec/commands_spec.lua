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

describe('commands.resolve_all', function()
  before_all(function()
    require('conflux').setup({})
  end)

  -- Two conflicts:
  --   line 1  (0-idx 0):  'before'
  --   line 2  (0-idx 1):  '<<<<<<< HEAD'
  --   line 3  (0-idx 2):  'ours1'
  --   line 4  (0-idx 3):  '======='
  --   line 5  (0-idx 4):  'theirs1'
  --   line 6  (0-idx 5):  '>>>>>>> branch'
  --   line 7  (0-idx 6):  'between'
  --   line 8  (0-idx 7):  '<<<<<<< HEAD'
  --   line 9  (0-idx 8):  'ours2'
  --   line 10 (0-idx 9):  '======='
  --   line 11 (0-idx 10): 'theirs2'
  --   line 12 (0-idx 11): '>>>>>>> branch'
  --   line 13 (0-idx 12): 'after'
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

  it('resolves all conflict blocks across the buffer', function()
    local blocks = detect.scan(bufnr)
    commands.resolve_all(bufnr, blocks, 'ours')
    eq(
      { 'before', 'ours1', 'between', 'ours2', 'after' },
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    )
  end)

  it('returns empty table when no conflicts', function()
    local new_blocks = commands.resolve_all(bufnr, {}, 'ours')
    eq({}, new_blocks)
  end)

  it('all replacements are a single undo entry', function()
    -- Atomicity: resolve_all on N blocks must add fewer than N undo entries.
    -- If each buf_set_lines were separate, seq_cur would advance by N (=2 here).
    -- With undojoin the advance is at most 1 (may be 0 when joined with a prior
    -- change from the test setup, which is fine).
    local seq_before = vim.api.nvim_buf_call(bufnr, function()
      return vim.fn.undotree().seq_cur
    end)

    local blocks = detect.scan(bufnr)
    local num_blocks = #blocks -- 2

    commands.resolve_all(bufnr, blocks, 'ours')

    local seq_after = vim.api.nvim_buf_call(bufnr, function()
      return vim.fn.undotree().seq_cur
    end)

    local new_entries = seq_after - seq_before
    assert(
      new_entries < num_blocks,
      ('atomicity: expected fewer than %d undo entries for %d blocks, got %d'):format(
        num_blocks,
        num_blocks,
        new_entries
      )
    )
  end)
end)
