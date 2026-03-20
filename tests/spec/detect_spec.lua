local detect = require('conflux.detect')

local bufnr

describe('detect.scan', function()
  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
  end)

  after_each(function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it('2-way conflict / returns correct blocks', function()
    local lines = vim.fn.readfile('tests/fixtures/two-way.txt')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    local blocks = detect.scan(bufnr)

    eq(2, #blocks)

    local b = blocks[1]
    eq(2, b.ours_marker)
    eq(3, b.ours_start)
    eq(5, b.ours_end) -- ours_end == sep: detect.lua sets both to the ======= line index
    eq(5, b.sep)
    eq(6, b.theirs_start)
    eq(8, b.theirs_end) -- theirs_end == their_marker: detect.lua sets both to the >>>>>>> line index
    eq(8, b.their_marker)
  end)

  it('3-way diff3 / parses ancestor section', function()
    local lines = vim.fn.readfile('tests/fixtures/three-way.txt')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    local blocks = detect.scan(bufnr)

    eq(1, #blocks)

    local b = blocks[1]
    eq(2, b.ours_marker)
    eq(3, b.ours_start)
    eq(5, b.ours_end) -- ours_end == anc_marker: both point to the ||||||| line
    eq(5, b.anc_marker)
    eq(6, b.anc_start)
    eq(8, b.anc_end) -- anc_end == sep: both point to the ======= line
    eq(8, b.sep)
    eq(9, b.theirs_start)
    eq(11, b.theirs_end) -- theirs_end == their_marker: both point to the >>>>>>> line
    eq(11, b.their_marker)
  end)

  it('empty ours section / ours_start equals ours_end', function()
    local lines = vim.fn.readfile('tests/fixtures/empty-section.txt')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    local blocks = detect.scan(bufnr)

    -- empty-section.txt has 2 blocks; block 1 has empty ours
    eq(2, #blocks)

    local b = blocks[1]
    eq(2, b.ours_marker)
    eq(3, b.ours_start)
    eq(3, b.ours_end) -- ours_start == ours_end: no ours content; also equals sep (======= line)
    eq(3, b.sep)
    eq(4, b.theirs_start)
    eq(5, b.theirs_end) -- theirs_end == their_marker: both point to the >>>>>>> line
    eq(5, b.their_marker)
  end)

  it('no conflict markers / returns empty list', function()
    local lines = vim.fn.readfile('tests/fixtures/no-conflict.txt')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    local blocks = detect.scan(bufnr)

    eq(0, #blocks)
  end)

  it('malformed: >>>>>>> before <<<<<<< / discards leading garbage', function()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      '>>>>>>> oops', -- 0: stray closer, no opener — discarded
      '<<<<<<< HEAD', -- 1: valid opener
      'a', -- 2
      '=======', -- 3
      'b', -- 4
      '>>>>>>> end', -- 5: valid closer
    })
    local blocks = detect.scan(bufnr)

    eq(1, #blocks) -- only the valid block survives
    eq(1, blocks[1].ours_marker)
  end)
end)
