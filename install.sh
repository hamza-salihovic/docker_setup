#!/usr/bin/env bash

set -e

# --- Configuration ---
# Global environment settings
DEV_ENV_DIR="$HOME/.docker-dev-env"
IMAGE_NAME="42-dev-env:latest"

# URLs for project-specific files
DEVCONTAINER_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/devcontainer.json"
GDB_SETUP_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/setup-gdb.sh"
GDB_HELP_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/GDB_Help.md"

# --- Helper Functions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INSTALL]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[INSTALL]${NC} $1"
}

print_error() {
    echo -e "${RED}[INSTALL ERROR]${NC} $1"
}

# --- Main Script ---

# 1. Check for Docker
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    print_error "Docker is not installed or not running. Please start Docker first."
    exit 1
fi

# 2. Check and set up the global environment if needed
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    print_warning "Image '$IMAGE_NAME' not found. Setting up global environment..."

    # Create directory and files
    mkdir -p "$DEV_ENV_DIR"
    
    # Create Dockerfile
    cat > "$DEV_ENV_DIR/Dockerfile" << 'EOF'
# Start from Ubuntu 22.04 (Jammy Jellyfish)
FROM ubuntu:22.04

# Set non-interactive frontend to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Add LLVM and GCC repositories
RUN apt-get update && apt-get -y install \
    wget \
    gnupg \
    software-properties-common \
    && wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-12 main" \
    && add-apt-repository ppa:ubuntu-toolchain-r/test

# Update the system and install utils (FIXED VERSION PINNING)
RUN apt-get update && apt-get install -y \
    sudo \
    cmake \
    meson \
    valgrind \
    build-essential \
    binutils \
    clang \
    clang-14 \
    clang-12 \
    lldb-12 \
    gdb \
    gcc-11 \
    g++-11 \
    gcc-10 \
    g++-10 \
    zsh \
    git \
    wget \
    curl \
    python3 python3-venv python3-pip \
    libreadline-dev \
    libreadline8 \
    xorg libxext-dev zlib1g-dev libbsd-dev \
    libcmocka-dev \
    pkg-config \
    cppcheck \
    clangd \
    man-db \
    manpages-dev \
    manpages-posix-dev \
    file \
    clang-format \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# --- INSERT THE NEW SNIPPET HERE ---

# Add Neovim PPA and install latest stable version
RUN add-apt-repository ppa:neovim-ppa/stable -y \
    && apt-get update && apt-get install -y neovim

# Install Powerlevel10k theme for Oh My Zsh
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k \
    && echo 'source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc \
    && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# --- END OF NEW SNIPPET ---

# Set up compiler aliases
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 100 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/clang-12 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-12 100

# Build all source tools in ONE LAYER (FIXED VALGRIND URL)
RUN wget https://sourceware.org/pub/valgrind/valgrind-3.18.1.tar.bz2 \
    && tar -xjf valgrind-3.18.1.tar.bz2 \
    && cd valgrind-3.18.1 \
    && ./configure \
    && make \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -rf valgrind-3.18.1* \
    && wget http://ftp.gnu.org/gnu/make/make-4.3.tar.gz \
    && tar -xvzf make-4.3.tar.gz \
    && cd make-4.3 \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf make-4.3* \
    && wget https://ftp.gnu.org/gnu/readline/readline-8.1.tar.gz \
    && tar -xzvf readline-8.1.tar.gz \
    && cd readline-8.1 \
    && ./configure --enable-shared \
    && make \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -rf readline-8.1*

# Create a virtual environment and activate it
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages in one go
RUN python3 -m pip install --upgrade pip setuptools && \
    python3 -m pip install norminette c_formatter_42

# Fix c_formatter_42 binary compatibility issue
RUN cp /usr/bin/clang-format /opt/venv/lib/python3.10/site-packages/c_formatter_42/data/clang-format-linux && \
    chmod +x /opt/venv/lib/python3.10/site-packages/c_formatter_42/data/clang-format-linux

# Install MLX library
RUN git clone https://github.com/42Paris/minilibx-linux.git /tmp/mlx \
    && cd /tmp/mlx \
    && make \
    && cp mlx.h /usr/local/include \
    && cp libmlx.a /usr/local/lib \
    && cd / \
    && rm -rf /tmp/mlx

# Install francinette
RUN bash -c "$(curl -fsSL https://raw.github.com/xicodomingues/francinette/master/bin/install.sh)"

# Install oh-my-zsh (suppress error if it fails)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

# Create persistent directories for caching
RUN mkdir -p /tmp/build-cache /tmp/test-results /root/.gdb_history_dir

# Configure GDB with enhanced settings (from your original)
RUN echo '# GDB Dashboard configuration' > /root/.gdbinit && \
    echo 'set disassembly-flavor intel' >> /root/.gdbinit && \
    echo 'set print pretty on' >> /root/.gdbinit && \
    echo 'set print array on' >> /root/.gdbinit && \
    echo 'set print array-indexes on' >> /root/.gdbinit && \
    echo 'set history save on' >> /root/.gdbinit && \
    echo 'set history size 10000' >> /root/.gdbinit && \
    echo 'set history filename ~/.gdb_history_dir/gdb_history' >> /root/.gdbinit && \
    echo '' >> /root/.gdbinit && \
    echo '# Better debugging experience' >> /root/.gdbinit && \
    echo 'set pagination off' >> /root/.gdbinit && \
    echo 'set confirm off' >> /root/.gdbinit && \
    echo 'set verbose off' >> /root/.gdbinit && \
    echo '' >> /root/.gdbinit && \
    echo '# Custom commands' >> /root/.gdbinit && \
    echo 'define hook-stop' >> /root/.gdbinit && \
    echo '    info registers' >> /root/.gdbinit && \
    echo '    x/10i $pc' >> /root/.gdbinit && \
    echo '    info locals' >> /root/.gdbinit && \
    echo '    backtrace 3' >> /root/.gdbinit && \
    echo 'end' >> /root/.gdbinit && \
    echo '' >> /root/.gdbinit && \
    echo '# Useful aliases' >> /root/.gdbinit && \
    echo 'alias -a xi = x/10i' >> /root/.gdbinit && \
    echo 'alias -a xc = x/32c' >> /root/.gdbinit && \
    echo 'alias -a xs = x/8s' >> /root/.gdbinit && \
    echo 'alias -a xw = x/8wx' >> /root/.gdbinit

# Set the default working directory (will be overridden by volume mounts)
WORKDIR /workspace

# Default command
CMD ["/bin/zsh"]
EOF

    # Create docker-compose.yml
    cat > "$DEV_ENV_DIR/docker-compose.yml" << 'EOF'
services:
  dev:
    build:
      context: .
      dockerfile: Dockerfile
    image: 42-dev-env:latest
    container_name: 42-dev-reusable
    volumes:
      # Mount current directory as workspace
      - "${PWD}:/workspace:cached"
      # Persistent build cache across all projects
      - build_cache:/tmp/build-cache
      - test_results:/tmp/test-results
      - gdb_history:/root/.gdb_history_dir
      # Your host config files (read-only to avoid conflicts)
      - "${HOME}/.ssh:/root/.ssh:ro"
      - "${HOME}/.gitconfig:/root/.gitconfig:ro"
    working_dir: /workspace
    environment:
      - TERM=xterm-256color
      - WAKATIME_API_KEY=${WAKATIME_API_KEY}
    stdin_open: true
    tty: true
    privileged: true

volumes:
  build_cache:
  test_results:
  gdb_history:
EOF

    # Build the image
    print_status "Building image '$IMAGE_NAME'. This may take a while..."
    (cd "$DEV_ENV_DIR" && docker-compose build)
fi

# 3. Set up the current project's .devcontainer directory
print_status "Setting up .devcontainer for the current project..."
mkdir -p .devcontainer

# Download project-specific files
curl -fsSL "$DEVCONTAINER_URL" -o .devcontainer/devcontainer.json
curl -fsSL "$GDB_SETUP_URL" -o .devcontainer/setup-gdb.sh
curl -fsSL "$GDB_HELP_URL" -o .devcontainer/GDB_Help.md

print_status "Setup complete. You can now use 'Reopen in Container' in VSCode."
