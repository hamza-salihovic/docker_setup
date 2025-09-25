#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Initializing Docker Development Environment..."

# Check Docker installation
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop for Mac."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi

# Enable BuildKit
export DOCKER_BUILDKIT=1

# Create necessary directories
mkdir -p "$PROJECT_ROOT"/{build,scripts,.devcontainer}

# Copy environment file if it doesn't exist
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "📝 Creating .env file..."
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env" 2>/dev/null || true
    echo "Please update .env with your 42 username if needed"
fi

# Build multi-platform images
echo "🔨 Building Docker images..."
echo "This may take 10-15 minutes on first run..."

# Build ARM64 image (native for M4 Pro)
docker buildx build \
    --platform linux/arm64 \
    --tag 42-dev:arm64 \
    --cache-from type=local,src=/tmp/.buildx-cache \
    --cache-to type=local,dest=/tmp/.buildx-cache,mode=max \
    --load \
    -f Dockerfile.optimized .

# Build x86_64 image for testing
read -p "Do you want to build x86_64 image for campus compatibility testing? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker buildx build \
        --platform linux/amd64 \
        --tag 42-dev:amd64 \
        --cache-from type=local,src=/tmp/.buildx-cache \
        --cache-to type=local,dest=/tmp/.buildx-cache,mode=max \
        --load \
        -f Dockerfile.optimized .
fi

# Create Docker volumes
echo "📦 Creating persistent volumes..."
docker volume create ccache-data
docker volume create build-cache

echo "✅ Docker environment initialized successfully!"
echo ""
echo "Quick Start Commands:"
echo "  ./scripts/docker-dev.sh    - Start ARM64 dev container"
echo "  ./scripts/docker-test.sh   - Test in x86_64 container"
echo "  ./scripts/docker-build.sh  - Build your project"