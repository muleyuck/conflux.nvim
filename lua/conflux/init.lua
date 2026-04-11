local M = {}

M._attached = {} -- { [bufnr] = { blocks = list } }
M._timers = {} -- { [bufnr] = uv_timer_t }  debounce timers for TextChangedI
M._is_setup = false

--- Initialize conflux with user config.
--- @param user_config table|nil
function M.setup(user_config)
  local config = require('conflux.config')
  local highlight = require('conflux.highlight')

  config.apply(user_config or {})
  highlight.init()

  local cfg = config.get()
  if cfg.default_mappings then
    local qfkey = cfg.quickfix_keymaps and cfg.quickfix_keymaps.open
    if qfkey and qfkey ~= '' then
      vim.keymap.set('n', qfkey, function()
        require('conflux.quickfix').quickfix()
      end, { desc = 'Conflux: open project quickfix' })
    end
  end

  M._is_setup = true
end

--- Return whether setup() has been called.
--- @return boolean
function M.is_setup()
  return M._is_setup
end

--- Handle ColorScheme change: redefine highlights and re-apply to all attached buffers.
function M.on_colorscheme()
  local hl = require('conflux.highlight')
  if not hl.is_initialized() then
    return
  end
  hl.redefine_highlights()
  for bufnr, state in pairs(M._attached) do
    hl.apply(bufnr, state.blocks)
  end
end

--- Return the cached blocks for a buffer, or nil if not attached.
--- @param bufnr number
--- @return table|nil
function M.get_blocks(bufnr)
  local state = M._attached[bufnr]
  return state and state.blocks or nil
end

--- Update the cached blocks for a buffer.
--- @param bufnr number
--- @param blocks table
function M.set_blocks(bufnr, blocks)
  blocks = blocks or {}
  if M._attached[bufnr] then
    M._attached[bufnr].blocks = blocks
  end
  -- If all conflicts resolved, detach
  if #blocks == 0 and M._attached[bufnr] then
    M.detach(bufnr)
  end
end

--- Try to attach conflux to a buffer if it has conflicts.
--- @param bufnr number
function M.try_attach(bufnr)
  if not M._is_setup then
    return
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local detect = require('conflux.detect')

  if M._attached[bufnr] then
    -- Already attached: re-scan in case file changed
    local blocks = detect.scan(bufnr)
    if #blocks == 0 then
      M.detach(bufnr)
    else
      M._attached[bufnr].blocks = blocks
      require('conflux.highlight').apply(bufnr, blocks)
    end
    return
  end

  local blocks = detect.scan(bufnr)
  if #blocks > 0 then
    M._attach(bufnr, blocks)
  end
end

--- Attach conflux to a buffer: highlight and set keymaps.
--- @param bufnr number
--- @param blocks table  pre-scanned conflict blocks (non-empty)
function M._attach(bufnr, blocks)
  local highlight = require('conflux.highlight')
  local config = require('conflux.config')

  M._attached[bufnr] = { blocks = blocks }
  highlight.apply(bufnr, blocks)

  local cfg = config.get()

  if cfg.default_mappings then
    for action, key in pairs(cfg.keymaps) do
      vim.keymap.set('n', key, function()
        local current_blocks = M._attached[bufnr] and M._attached[bufnr].blocks or {}
        local new_blocks = require('conflux.commands').resolve(bufnr, current_blocks, action)
        M.set_blocks(bufnr, new_blocks or {})
      end, {
        buffer = bufnr,
        desc = 'Conflux: apply ' .. action,
      })
    end

    for action, key in pairs(cfg.all_keymaps) do
      vim.keymap.set('n', key, function()
        local current_blocks = M._attached[bufnr] and M._attached[bufnr].blocks or {}
        local new_blocks = require('conflux.commands').resolve_all(bufnr, current_blocks, action)
        M.set_blocks(bufnr, new_blocks or {})
      end, {
        buffer = bufnr,
        desc = 'Conflux: apply all ' .. action,
      })
    end

    for action, key in pairs(cfg.nav_keymaps) do
      vim.keymap.set('n', key, function()
        local current_blocks = M._attached[bufnr] and M._attached[bufnr].blocks or {}
        require('conflux.navigate')[action](bufnr, current_blocks)
      end, {
        buffer = bufnr,
        desc = 'Conflux: ' .. action .. ' conflict',
      })
    end
  end

  -- Per-buffer autocommands (two augroups: watch survives detach, buf is cleared on detach)
  local watch_group = vim.api.nvim_create_augroup('ConfluxBufWatch' .. bufnr, { clear = true })
  local buf_group = vim.api.nvim_create_augroup('ConfluxBuf' .. bufnr, { clear = true })

  -- Re-scan on in-memory text changes (e.g. undo restoring conflict markers)
  vim.api.nvim_create_autocmd('TextChanged', {
    buffer = bufnr,
    group = watch_group,
    callback = function()
      M.try_attach(bufnr)
    end,
  })

  -- Re-scan during insert mode with debounce (150ms) to match VSCode real-time update
  vim.api.nvim_create_autocmd('TextChangedI', {
    buffer = bufnr,
    group = watch_group,
    callback = function()
      if M._timers[bufnr] then
        M._timers[bufnr]:stop()
        M._timers[bufnr]:close()
      end
      local timer = vim.uv.new_timer()
      M._timers[bufnr] = timer
      timer:start(
        150,
        0,
        vim.schedule_wrap(function()
          timer:close()
          M._timers[bufnr] = nil
          M.try_attach(bufnr)
        end)
      )
    end,
  })

  -- Auto-detach and full cleanup on buffer delete
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = bufnr,
    group = buf_group,
    once = true,
    callback = function()
      M.detach(bufnr)
      pcall(vim.api.nvim_del_augroup_by_name, 'ConfluxBufWatch' .. bufnr)
    end,
  })
end

--- Detach conflux from a buffer: clear highlights and keymaps.
--- @param bufnr number
function M.detach(bufnr)
  if not M._attached[bufnr] then
    return
  end

  local highlight = require('conflux.highlight')
  highlight.clear(bufnr)

  -- Remove keymaps if they exist
  local ok, config = pcall(require, 'conflux.config')
  if ok then
    local cfg_ok, cfg = pcall(config.get)
    if cfg_ok and cfg.default_mappings then
      for _, key in pairs(cfg.keymaps) do
        pcall(vim.keymap.del, 'n', key, { buffer = bufnr })
      end
      for _, key in pairs(cfg.all_keymaps) do
        pcall(vim.keymap.del, 'n', key, { buffer = bufnr })
      end
      for _, key in pairs(cfg.nav_keymaps) do
        pcall(vim.keymap.del, 'n', key, { buffer = bufnr })
      end
    end
  end

  M._attached[bufnr] = nil

  -- Cancel any pending debounce timer
  if M._timers[bufnr] then
    M._timers[bufnr]:stop()
    M._timers[bufnr]:close()
    M._timers[bufnr] = nil
  end

  -- Clean up the attached-state augroup (watch augroup is intentionally kept)
  pcall(vim.api.nvim_del_augroup_by_name, 'ConfluxBuf' .. bufnr)
end

return M
