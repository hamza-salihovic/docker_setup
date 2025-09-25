# GDB Help - Enhanced 42 School Configuration

## Quick Start

```bash
# Compile with debug symbols
gcc -g -o program program.c

# Start GDB
gdb ./program
```


## Auto-Refresh Commands (Enhanced)

These commands automatically refresh the TUI - no manual `refresh` needed!


| Command | Shortcut | Description |
| :-- | :-- | :-- |
| `run` | `r` | Start program (auto-refreshes) |
| `next` | `n` | Step over line (auto-refreshes) |
| `step` | `s` | Step into function (auto-refreshes) |
| `continue` | `c` | Continue execution (auto-refreshes) |
| `finish` |  | Run to end of function |
| `until` |  | Run to specified location |

## Breakpoints \& Control

| Command | Example | Description |
| :-- | :-- | :-- |
| `break` or `b` | `b main` | Break at function |
|  | `b file.c:42` | Break at line 42 |
|  | `b *0x8048000` | Break at address |
| `delete` | `delete 1` | Delete breakpoint 1 |
| `disable` | `disable 2` | Disable breakpoint 2 |
| `enable` | `enable 2` | Enable breakpoint 2 |
| `info breakpoints` |  | List all breakpoints |
| `clear` | `clear main` | Clear breakpoint at function |

## Enhanced Custom Commands

| Command | Description |
| :-- | :-- |
| `toggle-local` | Toggle automatic local variable display on stops |
| `reset-layout` | Fix corrupted TUI display (rebuilds layout) |

## TUI \& Focus Shortcuts

| Shortcut | Command | Description |
| :-- | :-- | :-- |
| `fc` | `focus cmd` | Focus command window |
| `fs` | `focus src` | Focus source window |
| `rf` | `refresh` | Manual refresh (rarely needed) |
| **Ctrl+X A** |  | Toggle TUI mode on/off |
| **Ctrl+L** |  | Refresh screen (alternative) |

## Memory Examination Aliases

| Alias | Full Command | Description |
| :-- | :-- | :-- |
| `xi` | `x/10i $pc` | Examine 10 instructions at current location |
| `xc` | `x/32c` | Examine 32 characters |
| `xs` | `x/8s` | Examine 8 strings |
| `xw` | `x/8wx` | Examine 8 words in hexadecimal |

## Information \& Inspection

| Command | Shortcut | Description |
| :-- | :-- | :-- |
| `print` | `p variable` | Print variable value |
| `backtrace` | `bt` | Show call stack |
| `info locals` |  | Show local variables |
| `info args` |  | Show function arguments |
| `info registers` |  | Show CPU registers |
| `list` | `l` | Show source code around current line |
| `whatis var` |  | Show variable type |
| `ptype var` |  | Show detailed type info |

## Navigation

| Command | Description |
| :-- | :-- |
| `up` | Move up one stack frame |
| `down` | Move down one stack frame |
| `frame 2` | Switch to frame 2 |
| `list 1,10` | Show lines 1-10 |
| `list func` | Show function code |

## Variable Manipulation

| Command | Example | Description |
| :-- | :-- | :-- |
| `set var = value` | `set x = 42` | Change variable value |
| `print *ptr` |  | Dereference pointer |
| `print array[^0]@10` |  | Print 10 array elements |
| `p/x variable` |  | Print in hexadecimal |
| `p/d variable` |  | Print in decimal |
| `p/t variable` |  | Print in binary |

## Enhanced Features (Auto-Enabled)

- **Intel Assembly Syntax**: Easier to read disassembly
- **Pretty Printing**: Structures display nicely
- **Command History**: Saved in `~/.gdb_history_dir/gdb_history`
- **Auto-Display on Stop**: Shows registers, instructions, locals, backtrace
- **Array Indexing**: Arrays show with , ,  indices[^9][^10]
- **TUI Source Layout**: Source code window enabled by default


## Memory Examination Advanced

| Command | Description |
| :-- | :-- |
| `x/10i $pc` | Show 10 instructions at program counter |
| `x/20xb &var` | Show 20 bytes in hex at variable address |
| `x/4xw $sp` | Show 4 words at stack pointer |
| `disas main` | Disassemble main function |
| `disas` | Disassemble current function |

## Quick Tips

1. **Use `toggle-local`** to see variables automatically on each stop
2. **Press Enter** to repeat the last command
3. **Use `reset-layout`** if TUI gets corrupted
4. **Tab completion** works for commands and variable names
5. **All debugging commands auto-refresh** - no manual refresh needed!
6. **Command history** persists between sessions
7. **Focus stays on CMD window** for easy typing

## Troubleshooting

- **Display corrupted**: Use `reset-layout`
- **Can't see variables**: Use `info locals` or `toggle-local`
- **Wrong assembly syntax**: Config uses Intel (easier to read)
- **History not saving**: Check `~/.gdb_history_dir/` exists

This enhanced GDB configuration makes debugging 42 school projects much more efficient with auto-refresh, persistent history, and smart defaults!