if vim.g.loaded_conflux then
  return
end
vim.g.loaded_conflux = true

local augroup = vim.api.nvim_create_augroup('Conflux', { clear = true })

-- Detect and attach on buffer read/write
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
  group = augroup,
  callback = function(ev)
    local ok, conflux = pcall(require, 'conflux')
    if ok and conflux.is_setup() then
      conflux.try_attach(ev.buf)
    end
  end,
})

-- Redefine highlights after colorscheme change
vim.api.nvim_create_autocmd('ColorScheme', {
  group = augroup,
  callback = function()
    local ok, conflux = pcall(require, 'conflux')
    if ok and conflux.is_setup() then
      conflux.on_colorscheme()
    end
  end,
})

-- Helper to build command callbacks
local function make_cmd(action, method)
  method = method or 'resolve'
  return function()
    local ok, conflux = pcall(require, 'conflux')
    if not ok then
      vim.notify('conflux: plugin not loaded', vim.log.levels.ERROR)
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local blocks = conflux.get_blocks(bufnr)
    if not blocks then
      vim.notify('conflux: no conflicts tracked in this buffer', vim.log.levels.WARN)
      return
    end
    local new_blocks = require('conflux.commands')[method](bufnr, blocks, action)
    conflux.set_blocks(bufnr, new_blocks or {})
  end
end

-- Helper to build navigation command callbacks.
-- Cannot reuse make_cmd because navigate functions return nothing (not new_blocks).
local function make_nav_cmd(direction)
  return function()
    local ok, conflux = pcall(require, 'conflux')
    if not ok then
      vim.notify('conflux: plugin not loaded', vim.log.levels.ERROR)
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local blocks = conflux.get_blocks(bufnr)
    if not blocks then
      vim.notify('conflux: no conflicts tracked in this buffer', vim.log.levels.WARN)
      return
    end
    require('conflux.navigate')[direction](bufnr, blocks)
  end
end

vim.api.nvim_create_user_command(
  'ConfluxOurs',
  make_cmd('ours'),
  { desc = 'Keep ours (current) changes' }
)
vim.api.nvim_create_user_command(
  'ConfluxTheirs',
  make_cmd('theirs'),
  { desc = 'Keep theirs (incoming) changes' }
)
vim.api.nvim_create_user_command(
  'ConfluxBoth',
  make_cmd('both'),
  { desc = 'Keep both changes (ours first)' }
)
vim.api.nvim_create_user_command('ConfluxNone', make_cmd('none'), { desc = 'Discard both changes' })

vim.api.nvim_create_user_command(
  'ConfluxAllOurs',
  make_cmd('ours', 'resolve_all'),
  { desc = 'Keep ours (current) changes in all conflicts' }
)
vim.api.nvim_create_user_command(
  'ConfluxAllTheirs',
  make_cmd('theirs', 'resolve_all'),
  { desc = 'Keep theirs (incoming) changes in all conflicts' }
)
vim.api.nvim_create_user_command(
  'ConfluxAllBoth',
  make_cmd('both', 'resolve_all'),
  { desc = 'Keep both changes in all conflicts (ours first)' }
)
vim.api.nvim_create_user_command(
  'ConfluxAllNone',
  make_cmd('none', 'resolve_all'),
  { desc = 'Discard both changes in all conflicts' }
)
vim.api.nvim_create_user_command(
  'ConfluxNext',
  make_nav_cmd('next'),
  { desc = 'Jump to next conflict block' }
)
vim.api.nvim_create_user_command(
  'ConfluxPrev',
  make_nav_cmd('prev'),
  { desc = 'Jump to previous conflict block' }
)
vim.api.nvim_create_user_command('ConfluxQuickfix', function()
  local ok, quickfix = pcall(require, 'conflux.quickfix')
  if not ok then
    vim.notify('conflux: plugin not loaded', vim.log.levels.ERROR)
    return
  end
  quickfix.quickfix()
end, { desc = 'Populate quickfix list with all project conflict blocks' })
