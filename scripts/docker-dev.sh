#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
fi

# Parse arguments
PLATFORM="${1:-arm64}"
COMMAND="${2:-/bin/zsh}"

echo "🚀 Starting development container (${PLATFORM})..."

# Check if container is already running
if docker ps | grep -q 42-dev-${PLATFORM}; then
    echo "📎 Attaching to existing container..."
    docker exec -it 42-dev-${PLATFORM} ${COMMAND}
else
    echo "🆕 Creating new container..."
    cd "$PROJECT_ROOT"
    docker-compose run --rm \
        --service-ports \
        --name 42-dev-${PLATFORM} \
        dev ${COMMAND}
fi