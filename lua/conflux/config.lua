local M = {}

M.defaults = {
  highlights = {
    ours = { bg = '#2b4d2b' },
    ours_marker = { bg = '#3d6b3d', bold = true },
    ancestor = { bg = '#4d3d1a' },
    ancestor_marker = { bg = '#6b5a1a', bold = true },
    separator = { bg = '#3d3d3d', bold = true },
    theirs = { bg = '#1a2b4d' },
    theirs_marker = { bg = '#1a3d6b', bold = true },
    keymap_hint = { fg = '#99bb99' },
    all_keymap_hint = { fg = '#99aacc' },
  },
  default_mappings = true,
  show_keymap_hints = true,
  keymaps = {
    ours = 'co',
    theirs = 'ct',
    both = 'cb',
    none = 'cz',
  },
  all_keymaps = {
    ours = 'cO',
    theirs = 'cT',
    both = 'cB',
    none = 'cZ',
  },
}

M._config = nil

function M.apply(user_config)
  user_config = user_config or {}
  M._config = vim.tbl_deep_extend('force', M.defaults, user_config)
  return M._config
end

function M.get()
  if not M._config then
    error('conflux: setup() has not been called')
  end
  return M._config
end

return M
