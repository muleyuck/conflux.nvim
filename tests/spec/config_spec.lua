local config = require('conflux.config')

-- Reset config state before each test so tests are independent.
local function reset()
  config._config = nil
end

describe('config.apply / default_mappings = true (default)', function()
  before_each(reset)

  it('registers all default keys when called with no arguments', function()
    local cfg = config.apply({})
    eq('co', cfg.keymaps.ours)
    eq('ct', cfg.keymaps.theirs)
    eq('cb', cfg.keymaps.both)
    eq('cz', cfg.keymaps.none)
    eq('cO', cfg.all_keymaps.ours)
    eq('cT', cfg.all_keymaps.theirs)
    eq('cB', cfg.all_keymaps.both)
    eq('cZ', cfg.all_keymaps.none)
    eq(']c', cfg.nav_keymaps.next)
    eq('[c', cfg.nav_keymaps.prev)
    eq('cq', cfg.quickfix_keymaps.open)
  end)

  it('overrides individual key while keeping the rest', function()
    local cfg = config.apply({ keymaps = { ours = '<leader>co' } })
    eq('<leader>co', cfg.keymaps.ours)
    eq('ct', cfg.keymaps.theirs)
    eq('cb', cfg.keymaps.both)
    eq('cz', cfg.keymaps.none)
  end)

  it('disables an individual key when set to false', function()
    local cfg = config.apply({ keymaps = { none = false } })
    eq('co', cfg.keymaps.ours)
    eq('ct', cfg.keymaps.theirs)
    eq('cb', cfg.keymaps.both)
    eq(false, cfg.keymaps.none)
  end)

end)

describe('config.apply / default_mappings = false', function()
  before_each(reset)

  it('disables all default keys', function()
    local cfg = config.apply({ default_mappings = false })
    eq(false, cfg.keymaps.ours)
    eq(false, cfg.keymaps.theirs)
    eq(false, cfg.keymaps.both)
    eq(false, cfg.keymaps.none)
    eq(false, cfg.all_keymaps.ours)
    eq(false, cfg.all_keymaps.theirs)
    eq(false, cfg.all_keymaps.both)
    eq(false, cfg.all_keymaps.none)
    eq(false, cfg.nav_keymaps.next)
    eq(false, cfg.nav_keymaps.prev)
    eq(false, cfg.quickfix_keymaps.open)
  end)

  it('registers an explicitly provided key even when default_mappings = false', function()
    local cfg = config.apply({ default_mappings = false, keymaps = { ours = '<leader>co' } })
    eq('<leader>co', cfg.keymaps.ours)
    eq(false, cfg.keymaps.theirs)
    eq(false, cfg.keymaps.both)
    eq(false, cfg.keymaps.none)
  end)

  it('registers multiple explicitly provided keys', function()
    local cfg = config.apply({
      default_mappings = false,
      keymaps = { ours = '<leader>co', theirs = '<leader>ct' },
      nav_keymaps = { next = ']c' },
    })
    eq('<leader>co', cfg.keymaps.ours)
    eq('<leader>ct', cfg.keymaps.theirs)
    eq(false, cfg.keymaps.both)
    eq(false, cfg.keymaps.none)
    eq(']c', cfg.nav_keymaps.next)
    eq(false, cfg.nav_keymaps.prev)
  end)
end)

describe('config.get', function()
  before_each(reset)

  it('raises an error before setup() is called', function()
    error_matches('setup%(%) has not been called', function()
      config.get()
    end)
  end)

  it('returns the applied config after apply()', function()
    config.apply({})
    local cfg = config.get()
    ok(cfg ~= nil)
    eq('co', cfg.keymaps.ours)
  end)
end)
