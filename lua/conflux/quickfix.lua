local M = {}

function M.quickfix()
  local detect = require('conflux.detect')

  -- Resolve the git repository root
  local root_out = vim.fn.system({ 'git', 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 then
    vim.notify('conflux: not a git repository', vim.log.levels.WARN)
    return
  end
  local git_root = vim.trim(root_out)

  -- List files with unresolved conflicts
  local diff_out =
    vim.fn.system({ 'git', '-C', git_root, 'diff', '--name-only', '--diff-filter=U' })
  if vim.v.shell_error ~= 0 then
    vim.notify('conflux: git diff failed: ' .. vim.trim(diff_out), vim.log.levels.WARN)
    return
  end

  -- No conflict files; bail out before splitting
  if vim.trim(diff_out) == '' then
    vim.notify('conflux: no conflict files found', vim.log.levels.INFO)
    return
  end

  local files = {}
  for _, line in ipairs(vim.split(diff_out, '\n', { plain = true })) do
    local trimmed = vim.trim(line)
    if trimmed ~= '' then
      table.insert(files, trimmed)
    end
  end

  -- Parse each file via a scratch buffer and collect quickfix entries
  local qflist = {}
  for _, filepath in ipairs(files) do
    local fullpath = git_root .. '/' .. filepath
    local tmpbuf = vim.api.nvim_create_buf(false, true)
    local ok, lines = pcall(vim.fn.readfile, fullpath)
    if not ok then
      vim.api.nvim_buf_delete(tmpbuf, { force = true })
      vim.notify('conflux: failed to read ' .. fullpath, vim.log.levels.WARN)
    else
      vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, lines)
      local blocks = detect.scan(tmpbuf)
      vim.api.nvim_buf_delete(tmpbuf, { force = true })
      for i, block in ipairs(blocks) do
        table.insert(qflist, {
          filename = fullpath,
          lnum = block.ours_marker + 1,
          col = 1,
          text = string.format('conflict %d/%d', i, #blocks),
        })
      end
    end
  end

  vim.fn.setqflist(qflist)
  vim.cmd('copen')
end

return M
