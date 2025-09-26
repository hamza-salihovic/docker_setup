#!/usr/bin/env bash
set -e

# --- Configuration ---
DEV_ENV_DIR="$HOME/.docker-dev-env"
IMAGE_NAME="42-dev-env:latest"
DEVCONTAINER_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/devcontainer.json"
GDB_SETUP_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/setup-gdb.sh"
GDB_HELP_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/GDB_Help.md"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INSTALL]${NC} $*"; }
warn(){ echo -e "${YELLOW}[INSTALL]${NC} $*"; }
err(){ echo -e "${RED}[INSTALL ERROR]${NC} $*" >&2; }

# Check Docker
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  err "Docker not installed or not running"; exit 1
fi

# Setup global environment if image missing
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  warn "Image '$IMAGE_NAME' not found. Setting up global environment..."
  mkdir -p "$DEV_ENV_DIR"

  # Create Dockerfile (based on your original with additions)
  cat > "$DEV_ENV_DIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Add LLVM and GCC repositories
RUN apt-get update && apt-get -y install \
    wget \
    gnupg \
    software-properties-common \
    && wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-12 main" \
    && add-apt-repository ppa:ubuntu-toolchain-r/test

# Update system and install development tools
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

# Set up compiler aliases  
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 100 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/clang-12 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-12 100

# Add Neovim PPA and install latest version
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:neovim-ppa/stable \
    && apt-get update && apt-get install -y neovim \
    && rm -rf /var/lib/apt/lists/*

# Build tools from source (Valgrind, Make, Readline)
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

# Python environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN python3 -m pip install --upgrade pip setuptools \
    && python3 -m pip install norminette c_formatter_42
RUN cp /usr/bin/clang-format /opt/venv/lib/python3.10/site-packages/c_formatter_42/data/clang-format-linux \
    && chmod +x /opt/venv/lib/python3.10/site-packages/c_formatter_42/data/clang-format-linux

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

# Install Oh My Zsh (unattended mode for Docker)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlevel10k theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/themes/powerlevel10k \
    && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' /root/.zshrc

# Create persistent directories
RUN mkdir -p /tmp/build-cache /tmp/test-results /root/.gdb_history_dir

# Configure GDB with enhanced settings
RUN echo '# GDB Dashboard configuration' > /root/.gdbinit && \
    echo 'set disassembly-flavor intel' >> /root/.gdbinit && \
    echo 'set print pretty on' >> /root/.gdbinit && \
    echo 'set print array on' >> /root/.gdbinit && \
    echo 'set print array-indexes on' >> /root/.gdbinit && \
    echo 'set history save on' >> /root/.gdbinit && \
    echo 'set history size 10000' >> /root/.gdbinit && \
    echo 'set history filename ~/.gdb_history_dir/gdb_history' >> /root/.gdbinit && \
    echo 'set pagination off' >> /root/.gdbinit && \
    echo 'set confirm off' >> /root/.gdbinit && \
    echo 'set verbose off' >> /root/.gdbinit && \
    echo 'define hook-stop' >> /root/.gdbinit && \
    echo '    info registers' >> /root/.gdbinit && \
    echo '    x/10i $pc' >> /root/.gdbinit && \
    echo '    info locals' >> /root/.gdbinit && \
    echo '    backtrace 3' >> /root/.gdbinit && \
    echo 'end' >> /root/.gdbinit && \
    echo 'alias -a xi = x/10i' >> /root/.gdbinit && \
    echo 'alias -a xc = x/32c' >> /root/.gdbinit && \
    echo 'alias -a xs = x/8s' >> /root/.gdbinit && \
    echo 'alias -a xw = x/8wx' >> /root/.gdbinit

WORKDIR /workspace
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
      - "${PWD}:/workspace:cached"
      - build_cache:/tmp/build-cache
      - test_results:/tmp/test-results
      - gdb_history:/root/.gdb_history_dir
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

  # Create dev helper script (with docker compose support)
  cat > "$DEV_ENV_DIR/dev" << 'EOF'
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log(){ echo -e "${GREEN}[42-DEV]${NC} $*"; }
warn(){ echo -e "${YELLOW}[42-DEV]${NC} $*"; }
err(){ echo -e "${RED}[42-DEV ERROR]${NC} $*" >&2; exit 1; }

# Detect compose command
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  err "docker compose/docker-compose not found"
fi

docker info >/dev/null 2>&1 || err "Docker not running"
[[ -f "$COMPOSE_FILE" ]] || err "Compose file missing: $COMPOSE_FILE"

# Build image if missing
if ! docker image inspect 42-dev-env:latest >/dev/null 2>&1; then
  warn "Image missing. Building now..."
  (cd "$SCRIPT_DIR" && $COMPOSE build) || err "Build failed"
fi

log "Project: $(pwd) -> /workspace"

case "${1:-}" in
  bash)   $COMPOSE -f "$COMPOSE_FILE" run --rm dev /bin/bash ;;
  build)  (cd "$SCRIPT_DIR" && $COMPOSE build --no-cache) ;;
  clean)  $COMPOSE -f "$COMPOSE_FILE" down --volumes; docker system prune -f ;;
  info)   log "Image: 42-dev-env:latest | Compose: $COMPOSE_FILE" ;;
  *)      $COMPOSE -f "$COMPOSE_FILE" run --rm dev ;;
esac
EOF
  chmod +x "$DEV_ENV_DIR/dev"

  # Build the image
  info "Building '$IMAGE_NAME'..."
  (cd "$DEV_ENV_DIR" && docker compose build 2>/dev/null || docker-compose build)
fi

# Add dev to PATH
if ! command -v dev >/dev/null 2>&1; then
  case "$SHELL" in
    *zsh)  echo 'export PATH="$HOME/.docker-dev-env:$PATH"' >> ~/.zshrc ;;
    *bash) echo 'export PATH="$HOME/.docker-dev-env:$PATH"' >> ~/.bashrc ;;
    *)     warn "Add $HOME/.docker-dev-env to PATH manually" ;;
  esac
fi

# Setup .devcontainer for current project
info "Setting up .devcontainer for current project..."
mkdir -p .devcontainer

# Create corrected devcontainer.json (using shared image)
cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "42-Docker-DevEnv",
  "image": "42-dev-env:latest",
  "runArgs": ["--privileged"],
  "containerEnv": {
    "WAKATIME_API_KEY": "${localEnv:WAKATIME_API_KEY}"
  },
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.shell.linux": "/bin/zsh",
        "[c]": {
          "editor.defaultFormatter": "keyhr.42-c-format"
        },
        "editor.formatOnSave": false
      },
      "extensions": [
        "ms-vscode.cpptools-extension-pack",
        "ms-python.python",
        "github.copilot",
        "vadimcn.vscode-lldb",
        "eamodio.gitlens",
        "bbenoist.togglehs",
        "ms-vscode.makefile-tools",
        "timonwong.shellcheck",
        "esbenp.prettier-vscode",
        "kube.42header",
        "DoKca.42-ft-count-line",
        "ms-vsliveshare.vsliveshare",
        "dqisme.sync-scroll",
        "uctakeoff.vscode-counter",
        "tomoki1207.pdf",
        "keyhr.42-c-format",
        "WakaTime.vscode-wakatime",
        "saoudrizwan.claude-dev",
        "streetsidesoftware.code-spell-checker",
        "ms-vscode.vscode-websearchforcopilot",
        "ms-vscode.cpptools-themes",
        "aaron-bond.better-comments",
        "specstory.specstory-vscode",
        "ms-python.vscode-pylance",
        "kilocode.kilo-code",
        "llvm-vs-code-extensions.vscode-clangd",
        "alpha912.codebase-md"
      ]
    }
  },
  "initializeCommand": "mkdir -p ${env:HOME}/.ssh && touch ${env:HOME}/.gitconfig ${env:HOME}/.zshrc",
  "mounts": [
    "source=${env:HOME}/.ssh,target=/root/.ssh,type=bind,consistency=cached",
    "source=${env:HOME}/.gitconfig,target=/root/.gitconfig,type=bind,consistency=cached",
    "source=${env:HOME}/.zshrc,target=/root/.zshrc,type=bind,consistency=cached"
  ],
  "postCreateCommand": "bash .devcontainer/setup-gdb.sh"
}
EOF

# Download additional files
curl -fsSL "$GDB_SETUP_URL" -o .devcontainer/setup-gdb.sh 2>/dev/null || warn "Could not download setup-gdb.sh"
curl -fsSL "$GDB_HELP_URL" -o .devcontainer/GDB_Help.md 2>/dev/null || warn "Could not download GDB_Help.md"

info "Setup complete! Run 'dev' to start or use VSCode 'Reopen in Container'"
