local M = {}

M._ns_id = nil
M._hl_defined = false

local HL_GROUPS = {
  ours_marker = 'ConfluxOursMarker',
  ours = 'ConfluxOurs',
  ancestor_marker = 'ConfluxAncestorMarker',
  ancestor = 'ConfluxAncestor',
  separator = 'ConfluxSeparator',
  theirs = 'ConfluxTheirs',
  theirs_marker = 'ConfluxTheirsMarker',
}

--- Initialize the namespace. Must be called before apply/clear.
function M.init()
  if not M._ns_id then
    M._ns_id = vim.api.nvim_create_namespace('conflux')
  end
  M._define_highlights()
end

--- Define (or redefine) highlight groups from config. Idempotent.
function M._define_highlights()
  local ok, config = pcall(require, 'conflux.config')
  if not ok then
    return
  end
  local cfg_ok, cfg = pcall(config.get)
  if not cfg_ok then
    return
  end
  local hls = cfg.highlights

  local map = {
    ours_marker = HL_GROUPS.ours_marker,
    ours = HL_GROUPS.ours,
    ancestor_marker = HL_GROUPS.ancestor_marker,
    ancestor = HL_GROUPS.ancestor,
    separator = HL_GROUPS.separator,
    theirs = HL_GROUPS.theirs,
    theirs_marker = HL_GROUPS.theirs_marker,
  }

  for key, group in pairs(map) do
    if hls[key] then
      vim.api.nvim_set_hl(0, group, hls[key])
    end
  end

  M._hl_defined = true
end

--- Apply extmark highlights for all conflict blocks in a buffer.
--- @param bufnr number
--- @param blocks table
function M.apply(bufnr, blocks)
  if not M._ns_id then
    return
  end
  M.clear(bufnr)

  for _, block in ipairs(blocks) do
    -- <<<<<<< marker line
    M._mark_lines(bufnr, block.ours_marker, block.ours_marker + 1, HL_GROUPS.ours_marker)

    -- ours content lines
    if block.ours_start <= block.ours_end - 1 then
      M._mark_lines(bufnr, block.ours_start, block.ours_end, HL_GROUPS.ours)
    end

    -- ||||||| ancestor marker + content (diff3 only)
    if block.anc_marker then
      M._mark_lines(bufnr, block.anc_marker, block.anc_marker + 1, HL_GROUPS.ancestor_marker)
      if block.anc_start <= block.anc_end - 1 then
        M._mark_lines(bufnr, block.anc_start, block.anc_end, HL_GROUPS.ancestor)
      end
    end

    -- ======= separator line
    M._mark_lines(bufnr, block.sep, block.sep + 1, HL_GROUPS.separator)

    -- theirs content lines
    if block.theirs_start <= block.theirs_end - 1 then
      M._mark_lines(bufnr, block.theirs_start, block.theirs_end, HL_GROUPS.theirs)
    end

    -- >>>>>>> marker line
    M._mark_lines(bufnr, block.their_marker, block.their_marker + 1, HL_GROUPS.theirs_marker)
  end
end

--- Set extmarks for a range of lines [start_row, end_row) with a given hl_group.
--- @param bufnr number
--- @param start_row number  0-indexed inclusive
--- @param end_row number    0-indexed exclusive
--- @param hl_group string
function M._mark_lines(bufnr, start_row, end_row, hl_group)
  vim.api.nvim_buf_set_extmark(bufnr, M._ns_id, start_row, 0, {
    end_row = end_row,
    end_col = 0,
    hl_group = hl_group,
    hl_eol = true,
    priority = 100,
  })
end

--- Return whether the namespace has been initialized.
--- @return boolean
function M.is_initialized()
  return M._ns_id ~= nil
end

--- Redefine highlight groups (public entry point for colorscheme changes).
function M.redefine_highlights()
  M._define_highlights()
end

--- Clear all conflux extmarks from a buffer.
--- @param bufnr number
function M.clear(bufnr)
  if not M._ns_id then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, M._ns_id, 0, -1)
end

return M
