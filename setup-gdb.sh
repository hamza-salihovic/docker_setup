#!/bin/bash

# Create the .gdbinit file
cat > ~/.gdbinit << 'EOF'
layout src
define toggle-local
if $toggle_hook_enabled== 0
set $toggle_hook_enabled = 1
define hook-stop
info locals
info args
printf "========================\n"
end
printf "display-local enabled.\n"
else
set $toggle_hook_enabled = 0
define hook-stop
end
printf "display-local disabled.\n"
end
end
set $toggle_hook_enabled = 0
EOF

echo "GDB configuration installed successfully!"