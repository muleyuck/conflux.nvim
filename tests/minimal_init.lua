-- tests/minimal_init.lua
-- Minimal Neovim init for manual testing.
--
-- Usage:
--   nvim -u tests/minimal_init.lua tests/fixtures/two-way.txt
--
-- Override config via environment variables:
--   CONFLUX_KEYMAPS_OURS=<leader>o  nvim -u tests/minimal_init.lua tests/fixtures/two-way.txt
--   CONFLUX_DEFAULT_MAPPINGS=false   nvim -u tests/minimal_init.lua tests/fixtures/two-way.txt

vim.opt.runtimepath:prepend(vim.fn.getcwd())

local function env(name, default)
  local v = vim.env[name]
  return (v ~= nil and v ~= '') and v or default
end

local default_mappings = env('CONFLUX_DEFAULT_MAPPINGS', 'true') ~= 'false'

require('conflux').setup({
  default_mappings = default_mappings,
  keymaps = {
    ours   = env('CONFLUX_KEYMAPS_OURS',   'co'),
    theirs = env('CONFLUX_KEYMAPS_THEIRS', 'ct'),
    both   = env('CONFLUX_KEYMAPS_BOTH',   'cb'),
    none   = env('CONFLUX_KEYMAPS_NONE',   'c0'),
  },
  highlights = {
    ours            = { bg = env('CONFLUX_HL_OURS',            '#2b4d2b') },
    ours_marker     = { bg = env('CONFLUX_HL_OURS_MARKER',     '#3d6b3d'), bold = true },
    ancestor        = { bg = env('CONFLUX_HL_ANCESTOR',        '#4d3d1a') },
    ancestor_marker = { bg = env('CONFLUX_HL_ANCESTOR_MARKER', '#6b5a1a'), bold = true },
    separator       = { bg = env('CONFLUX_HL_SEPARATOR',       '#3d3d3d'), bold = true },
    theirs          = { bg = env('CONFLUX_HL_THEIRS',          '#1a2b4d') },
    theirs_marker   = { bg = env('CONFLUX_HL_THEIRS_MARKER',   '#1a3d6b'), bold = true },
  },
})
