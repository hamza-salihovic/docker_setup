#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🧪 Running tests in x86_64 container (campus compatibility)..."

# Check if we have a Makefile with test target
if [ -f "$PROJECT_ROOT/Makefile" ] && grep -q "^test:" "$PROJECT_ROOT/Makefile"; then
    # Build project first
    "$SCRIPT_DIR/docker-build.sh" amd64

    # Run tests
    cd "$PROJECT_ROOT"
    docker-compose run --rm test /bin/bash -c "
        cd /workspace
        make test
        valgrind --leak-check=full --show-leak-kinds=all ./a.out 2>&1 | tee valgrind-report.txt
        norminette src/*.c includes/*.h 2>/dev/null || norminette *.c *.h 2>/dev/null || echo 'No files to check with norminette'
    "
else
    echo "⚠️  No test target found in Makefile"
    echo "Running basic compilation and norm check..."
    
    cd "$PROJECT_ROOT"
    docker-compose run --rm test /bin/bash -c "
        cd /workspace
        # Try to compile all .c files if they exist
        if ls *.c 1> /dev/null 2>&1; then
            gcc -Wall -Wextra -Werror *.c -o test_program
            echo '✅ Compilation successful'
            
            # Run valgrind if executable exists
            if [ -f test_program ]; then
                valgrind --leak-check=full --show-leak-kinds=all ./test_program
            fi
        else
            echo 'No C files found to compile'
        fi
        
        # Run norminette
        norminette *.c *.h 2>/dev/null || echo 'No files to check with norminette'
    "
fi

echo "✅ Testing complete!"