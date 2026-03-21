# Changelog

## 1.0.0 (2026-03-21)


### Features

* add conflict block navigation with ]c/[c keymaps and ConfluxNext/ConfluxPrev commands ([59e78d2](https://github.com/muleyuck/conflux.nvim/commit/59e78d2b4fe0aacdedf8ad37fd54493d5d42f343))
* add core Lua modules for conflict detection, resolution, and configuration ([f75e0bd](https://github.com/muleyuck/conflux.nvim/commit/f75e0bd47a37f4ce80f471f41bf217bcb65b5803))
* add debounced TextChangedI re-scan for real-time conflict detection ([1c0fb32](https://github.com/muleyuck/conflux.nvim/commit/1c0fb32d5ea20dbb882d51deb491c246d79c1ef4))
* add extmark-based highlight module for conflict blocks ([8619d55](https://github.com/muleyuck/conflux.nvim/commit/8619d5548ca83cd1795f853a923ece00510e588c))
* add plugin entry point with autocommands and user commands ([a3fe84c](https://github.com/muleyuck/conflux.nvim/commit/a3fe84c89cb832c2658df65b4579ba1269d24217))
* add resolve-all commands/keymaps and rename none keymap from c0 to cz ([3be8fe1](https://github.com/muleyuck/conflux.nvim/commit/3be8fe10de213e8fe0c8fd9043755c7bdd89a17d))
* show right-aligned keymap hint on conflict marker lines ([f1fc820](https://github.com/muleyuck/conflux.nvim/commit/f1fc82015d27ab64e84131e307935bb52c1afb13))
* enable default_mappings by default ([eb55013](https://github.com/muleyuck/conflux.nvim/commit/eb55013d0c2438eacc17c321cc0f6a7e266ef246))


### Bug Fixes

* silently discard malformed or unterminated conflict blocks instead of erroring ([9135177](https://github.com/muleyuck/conflux.nvim/commit/913517744f905a0daee9aec0e0fa2584e71606ec))
* expose public API and fix cursor target window for non-focused buffers ([c5f3b6c](https://github.com/muleyuck/conflux.nvim/commit/c5f3b6c6bbc46e1aec4677a989dcfef2228dd2d6))


### Documentation

* add README and Vim help documentation ([fe2ebe6](https://github.com/muleyuck/conflux.nvim/commit/fe2ebe6678691a13ff0ad5cba0e493d2a594206a))
* add installation examples for vim-plug, mini.deps, and pathogen; fix repo name in lazy.nvim and packer.nvim examples ([9ca3e16](https://github.com/muleyuck/conflux.nvim/commit/9ca3e16e9413fa54910e38f8dfc3d1cf4bd310a7))
* fix placeholder repo name and add missing resolve-all, navigation, and all_keymap_hint docs ([bfbae82](https://github.com/muleyuck/conflux.nvim/commit/bfbae822aa0cc5a657b8e64697782b1253fd6ffe))
