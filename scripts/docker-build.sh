#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PLATFORM="${1:-arm64}"
TARGET="${2:-all}"

echo "🔨 Building project in ${PLATFORM} container..."

cd "$PROJECT_ROOT"

# Check if Docker image exists
if ! docker images | grep -q "42-dev.*${PLATFORM}"; then
    echo "⚠️  Docker image not found. Building..."
    docker buildx build \
        --platform linux/${PLATFORM} \
        --tag 42-dev:${PLATFORM} \
        --cache-from type=local,src=/tmp/.buildx-cache \
        --cache-to type=local,dest=/tmp/.buildx-cache,mode=max \
        --load \
        -f Dockerfile.optimized .
fi

# Run build command
docker run --rm \
    -v "$PROJECT_ROOT:/workspace:cached" \
    -v ccache-data:/cache/ccache \
    -v build-cache:/workspace/build \
    --platform linux/${PLATFORM} \
    42-dev:${PLATFORM} \
    /bin/bash -c "
        cd /workspace
        ccache -z
        if [ -f Makefile ]; then
            make ${TARGET} -j\$(nproc)
        else
            echo '⚠️  No Makefile found'
            # Try to compile all .c files
            if ls *.c 1> /dev/null 2>&1; then
                echo 'Compiling all .c files...'
                gcc -Wall -Wextra -Werror *.c -o program
            else
                echo 'No C files found to compile'
            fi
        fi
        ccache -s
    "

echo "✅ Build complete!"