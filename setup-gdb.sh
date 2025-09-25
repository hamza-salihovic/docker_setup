#!/bin/bash

cat > ~/.gdbinit << 'EOF'
# GDB Dashboard configuration
set disassembly-flavor intel
set print pretty on
set print array on
set print array-indexes on
set history save on
set history size 10000
set history filename ~/.gdb_history_dir/gdb_history
set pagination off
set confirm off
set verbose off

# TUI Layout and Focus
layout src
with pagination off -- focus cmd

# Auto-refresh hooks for common commands (prevents TUI corruption)
define hook-next
    refresh
end

define hook-step  
    refresh
end

define hook-continue
    refresh
end

define hook-finish
    refresh
end

define hook-until
    refresh
end

define hook-run
    refresh
end

# Override common commands to include refresh
define n
    next
    refresh
end

define s
    step  
    refresh
end

define c
    continue
    refresh
end

define r
    run
    refresh
end

# Your toggle-local function (fixed spacing)
define toggle-local
if $toggle_hook_enabled == 0
    set $toggle_hook_enabled = 1
    define hook-stop
        info locals
        info args
        printf "========================\n"
        refresh
    end
    printf "display-local enabled.\n"
else
    set $toggle_hook_enabled = 0
    define hook-stop
        refresh
    end
    printf "display-local disabled.\n"
end
end
set $toggle_hook_enabled = 0

# Enhanced stop hook with refresh
define hook-stop
    info registers
    x/10i $pc
    info locals
    backtrace 3
    refresh
end

# Useful aliases
alias -a xi = x/10i
alias -a xc = x/32c
alias -a xs = x/8s
alias -a xw = x/8wx

# Quick refresh alias
alias -a rf = refresh

# Focus shortcuts
alias -a fc = focus cmd
alias -a fs = focus src

# Custom command to reset layout if it gets messed up
define reset-layout
    tui disable
    tui enable
    layout src
    with pagination off -- focus cmd
    refresh
end

# Welcome message
printf "Enhanced 42 GDB Config Loaded!\n"
printf "Commands: n/s/c (auto-refresh), toggle-local, rf (refresh), fc (focus cmd)\n"
printf "reset-layout if display gets corrupted\n"
EOF

mkdir -p ~/.gdb_history_dir
echo "Enhanced GDB configuration installed!"
