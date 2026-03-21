# conflux.nvim

VSCode-like Git conflict resolution for Neovim.

conflux.nvim automatically detects conflict markers in your files and provides color-coded highlights plus quick commands to accept one side, both, or neither — without leaving Neovim.

## Features

- Color-coded extmark highlights for `<<<<<<<`, `=======`, and `>>>>>>>` blocks
- Full-line background highlights (VSCode style, using `hl_eol`)
- diff3 support: `|||||||` ancestor sections highlighted in a distinct color
- Buffer-local keymaps set automatically when a conflict file is opened
- Right-aligned keymap hint shown on each `<<<<<<<` marker line (`ours(co) | theirs(ct) | both(cb) | none(cz)`)
- Highlights restored after colorscheme changes
- Auto-detach when all conflicts are resolved

## Requirements

- Neovim >= 0.10

## Installation

### lazy.nvim

```lua
{
  'muleyuck/conflux.nvim',
  event = 'BufReadPost',
  opts  = {},   -- use defaults; or pass a config table
}
```

### vim-plug

```vim
Plug 'muleyuck/conflux.nvim'
```

Then in your `init.lua` (or `lua` block in `init.vim`):

```lua
require('conflux').setup()
```

### packer.nvim

```lua
use {
  'muleyuck/conflux.nvim',
  config = function()
    require('conflux').setup()
  end,
}
```

### mini.deps

```lua
MiniDeps.add('muleyuck/conflux.nvim')
require('conflux').setup()
```

### pathogen

```sh
cd ~/.config/nvim/bundle
git clone https://github.com/muleyuck/conflux.nvim
```

Then in your `init.lua`:

```lua
require('conflux').setup()
```

### Manual

Add the plugin directory to your `runtimepath` and call `setup()`:

```lua
vim.opt.rtp:prepend('/path/to/conflux.nvim')
require('conflux').setup()
```

## Configuration

All options are optional. Shown below are the defaults:

```lua
require('conflux').setup({
  -- Highlight group specs passed directly to nvim_set_hl().
  -- Use { bg = '#rrggbb' } or { link = 'SomeGroup' }.
  highlights = {
    ours             = { bg = '#2b4d2b' },
    ours_marker      = { bg = '#3d6b3d', bold = true },
    ancestor         = { bg = '#4d3d1a' },    -- diff3 only
    ancestor_marker  = { bg = '#6b5a1a', bold = true },
    separator        = { bg = '#3d3d3d', bold = true },
    theirs           = { bg = '#1a2b4d' },
    theirs_marker    = { bg = '#1a3d6b', bold = true },
    keymap_hint      = { fg = '#99bb99' },    -- virtual text hint on <<<<<<< line
  },

  -- Set false to disable the default buffer-local keymaps
  default_mappings = true,

  -- Set false to hide the right-aligned keymap hint on each <<<<<<< marker line
  show_keymap_hints = true,

  -- Keys for the default mappings
  keymaps = {
    ours   = 'co',
    theirs = 'ct',
    both   = 'cb',
    none   = 'cz',
  },
})
```

### Linking to existing highlight groups

```lua
require('conflux').setup({
  highlights = {
    ours   = { link = 'DiffAdd' },
    theirs = { link = 'DiffDelete' },
  },
})
```

## Commands

| Command          | Description                                  |
|------------------|----------------------------------------------|
| `:ConfluxOurs`   | Keep HEAD (ours) changes; discard theirs     |
| `:ConfluxTheirs` | Keep incoming (theirs) changes; discard ours |
| `:ConfluxBoth`   | Keep both changes (ours first, then theirs)  |
| `:ConfluxNone`   | Discard both sides entirely                  |

All commands act on the conflict block that contains the cursor.

## Default Keymaps

When a conflict file is opened, conflux sets buffer-local normal-mode keymaps:

| Key  | Action                        |
|------|-------------------------------|
| `co` | Accept ours (`:ConfluxOurs`)   |
| `ct` | Accept theirs (`:ConfluxTheirs`)|
| `cb` | Accept both (`:ConfluxBoth`)   |
| `cz` | Accept none (`:ConfluxNone`)   |

> **Note:** `co` and `ct` are two-key sequences that share the `c` prefix with
> Vim's built-in change operator. This causes a brief timeout delay when typing
> `c` followed by any key. To avoid this, disable default mappings and define
> your own:

```lua
require('conflux').setup({ default_mappings = false })

-- Then add your preferred keys, e.g. in an autocmd or after/plugin file:
vim.keymap.set('n', '<leader>co', '<Cmd>ConfluxOurs<CR>')
vim.keymap.set('n', '<leader>ct', '<Cmd>ConfluxTheirs<CR>')
vim.keymap.set('n', '<leader>cb', '<Cmd>ConfluxBoth<CR>')
vim.keymap.set('n', '<leader>cz', '<Cmd>ConfluxNone<CR>')
```

## Highlights

conflux defines these highlight groups (override them after `setup()`):

| Group                  | Used for                              |
|------------------------|---------------------------------------|
| `ConfluxOurs`          | Ours (HEAD) content lines             |
| `ConfluxOursMarker`    | `<<<<<<<` marker line                 |
| `ConfluxAncestor`      | Ancestor content lines (diff3)        |
| `ConfluxAncestorMarker`| `|||||||` marker line (diff3)         |
| `ConfluxSeparator`     | `=======` separator line              |
| `ConfluxTheirs`        | Theirs (incoming) content lines       |
| `ConfluxTheirsMarker`  | `>>>>>>>` marker line                 |
| `ConfluxKeymapHint`    | Right-aligned keymap hint virtual text|

## How it works

1. On `BufReadPost` / `BufWritePost`, conflux scans the buffer for `<<<<<<<`
   markers using a state machine that handles both standard and diff3 formats.
2. Each conflict block is highlighted via `nvim_buf_set_extmark` with
   `hl_eol = true` so backgrounds extend to the end of each line.
3. When a resolution command is issued, `nvim_buf_set_lines` replaces the
   entire block (markers included) with the chosen content lines.
4. The buffer is immediately re-scanned and highlights are updated.
5. When the last conflict is resolved, highlights and keymaps are removed.


## LICENCE

[The MIT Licence](https://github.com/muleyuck/conflux.nvim/blob/main/LICENSE)
