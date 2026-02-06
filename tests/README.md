# SmartMotion Playground / Test Files

Interactive test files for every SmartMotion preset. Open them in Neovim with SmartMotion loaded and follow the comment instructions.

## Quick Start

```vim
" Open a test file
:e tests/words_lines.lua

" Test multi-window: open a second file in a vertical split
:vsplit tests/search.lua
```

## Files

| File | Presets Covered |
|------|----------------|
| `words_lines.lua` | `w`, `b`, `e`, `ge`, `j`, `k` |
| `search.lua` | `s`, `S`, `f`, `F`, `t`, `T`, `;`, `,`, `gs`, native `/` search |
| `operators.lua` | Composable operators (`d`, `y`, `c`, `p`, `P` + any motion), until (`dt`, `dT`, `yt`, `yT`, `ct`, `cT`), remote (`rdw`, `rdl`, `ryw`, `ryl`), operator-pending (`>w`, `gUw`, etc.) |
| `treesitter.lua` | `]]`, `[[`, `]c`, `[c`, `]b`, `[b`, `daa`, `caa`, `yaa`, `dfn`, `cfn`, `yfn`, `saa` |
| `diagnostics.lua` | `]d`, `[d`, `]e`, `[e` (requires LSP) |
| `misc.lua` | `.` (repeat), `gmd`, `gmy` |

## Multi-Window Testing

SmartMotion labels appear across all visible windows for search, treesitter, and diagnostic motions. To test:

1. Open two files side by side: `:vsplit tests/treesitter.lua`
2. Press `s` or `]]` — labels should appear in **both** windows
3. Select a label in the other window — cursor jumps across

Word and line motions (`w`, `b`, `j`, `k`) stay in the current window.

## Tips

- Files can be freely edited during testing — use `:e!` to reload the original
- Press `ESC` at any label prompt to cancel cleanly
- Use `:checkhealth` to verify treesitter parsers are installed
- `diagnostics.lua` requires `lua_ls` or another LSP server to generate real diagnostics
