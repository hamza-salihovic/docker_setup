#!/usr/bin/env bash
set -e

DEV_ENV_DIR="$HOME/.docker-dev-env"
IMAGE_NAME="42-dev-env:latest"
DEVCONTAINER_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/devcontainer.json"
GDB_SETUP_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/setup-gdb.sh"
GDB_HELP_URL="https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/GDB_Help.md"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INSTALL]${NC} $*"; }
warn(){ echo -e "${YELLOW}[INSTALL]${NC} $*"; }
err(){ echo -e "${RED}[INSTALL ERROR]${NC} $*" >&2; }

# Docker check
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  err "Docker not installed or not running"; exit 1
fi

# Setup global environment if image missing
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  warn "Setting up global environment..."
  mkdir -p "$DEV_ENV_DIR"

  # Create Dockerfile with P10k ready to configure
  cat > "$DEV_ENV_DIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Add LLVM and GCC repositories
RUN apt-get update && apt-get -y install \
    wget gnupg software-properties-common \
    && wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-12 main" \
    && add-apt-repository ppa:ubuntu-toolchain-r/test

# Install development tools + Neovim PPA
RUN apt-get update && apt-get install -y \
    sudo cmake meson valgrind build-essential binutils \
    clang clang-14 clang-12 lldb-12 gdb \
    gcc-11 g++-11 gcc-10 g++-10 \
    zsh git wget curl \
    python3 python3-venv python3-pip \
    libreadline-dev libreadline8 xorg libxext-dev zlib1g-dev libbsd-dev \
    libcmocka-dev pkg-config cppcheck clangd \
    man-db manpages-dev manpages-posix-dev file clang-format \
    && add-apt-repository -y ppa:neovim-ppa/stable \
    && apt-get update && apt-get install -y neovim \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Set up compiler aliases
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 100 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100

# Build tools from source
RUN wget https://sourceware.org/pub/valgrind/valgrind-3.18.1.tar.bz2 \
    && tar -xjf valgrind-3.18.1.tar.bz2 && cd valgrind-3.18.1 \
    && ./configure && make && make install && ldconfig && cd .. && rm -rf valgrind-3.18.1* \
    && wget http://ftp.gnu.org/gnu/make/make-4.3.tar.gz \
    && tar -xvzf make-4.3.tar.gz && cd make-4.3 \
    && ./configure && make && make install && cd .. && rm -rf make-4.3* \
    && wget https://ftp.gnu.org/gnu/readline/readline-8.1.tar.gz \
    && tar -xzvf readline-8.1.tar.gz && cd readline-8.1 \
    && ./configure --enable-shared && make && make install && ldconfig && cd .. && rm -rf readline-8.1*

# Python environment and 42 tools
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN python3 -m pip install --upgrade pip setuptools \
    && python3 -m pip install norminette c_formatter_42 \
    && cp /usr/bin/clang-format /opt/venv/lib/python3.10/site-packages/c_formatter_42/data/clang-format-linux \
    && chmod +x /opt/venv/lib/python3.10/site-packages/c_formatter_42/data/clang-format-linux

# Install MLX and francinette
RUN git clone https://github.com/42Paris/minilibx-linux.git /tmp/mlx \
    && cd /tmp/mlx && make && cp mlx.h /usr/local/include && cp libmlx.a /usr/local/lib \
    && rm -rf /tmp/mlx
RUN bash -c "$(curl -fsSL https://raw.github.com/xicodomingues/francinette/master/bin/install.sh)"

# Install Oh My Zsh and Powerlevel10k WITHOUT pre-configuration
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k \
    && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' /root/.zshrc \
    && echo '' >> /root/.zshrc \
    && echo '# P10k configuration will be loaded from persistent volume if exists' >> /root/.zshrc \
    && echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> /root/.zshrc

# Create directories and GDB config
RUN mkdir -p /tmp/build-cache /tmp/test-results /root/.gdb_history_dir
RUN echo 'set disassembly-flavor intel\nset print pretty on\nset print array on\nset print array-indexes on\nset history save on\nset history size 10000\nset history filename ~/.gdb_history_dir/gdb_history\nset pagination off\nset confirm off\nset verbose off\ndefine hook-stop\n    info registers\n    x/10i $pc\n    info locals\n    backtrace 3\nend\nalias -a xi = x/10i\nalias -a xc = x/32c\nalias -a xs = x/8s\nalias -a xw = x/8wx' > /root/.gdbinit

WORKDIR /workspace
CMD ["/bin/zsh"]
EOF

  # Create docker-compose.yml with persistent P10k config volume
  cat > "$DEV_ENV_DIR/docker-compose.yml" << 'EOF'
services:
  dev:
    build: { context: ., dockerfile: Dockerfile }
    image: 42-dev-env:latest
    container_name: 42-dev-reusable
    volumes:
      - "${PWD}:/workspace:cached"
      - build_cache:/tmp/build-cache
      - test_results:/tmp/test-results
      - gdb_history:/root/.gdb_history_dir
      - p10k_config:/root/.p10k_persistent
      - "${HOME}/.ssh:/root/.ssh:ro"
      - "${HOME}/.gitconfig:/root/.gitconfig:ro"
    working_dir: /workspace
    environment:
      - TERM=xterm-256color
      - WAKATIME_API_KEY=${WAKATIME_API_KEY}
    stdin_open: true
    tty: true
    privileged: true
    # Copy P10k config from persistent volume on startup
    command: >
      bash -c "
        if [ -f /root/.p10k_persistent/.p10k.zsh ]; then
          cp /root/.p10k_persistent/.p10k.zsh /root/.p10k.zsh
        fi;
        exec /bin/zsh
      "

volumes:
  build_cache:
  test_results:
  gdb_history:
  p10k_config:
EOF

  # Create dev helper with P10k save function
  cat > "$DEV_ENV_DIR/dev" << 'EOF'
#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log(){ echo -e "${GREEN}[42-DEV]${NC} $*"; }
warn(){ echo -e "${YELLOW}[42-DEV]${NC} $*"; }
err(){ echo -e "${RED}[42-DEV ERROR]${NC} $*" >&2; exit 1; }

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  err "docker compose/docker-compose not found"
fi

docker info >/dev/null 2>&1 || err "Docker not running"
[[ -f "$COMPOSE_FILE" ]] || err "Compose file missing: $COMPOSE_FILE"

if ! docker image inspect 42-dev-env:latest >/dev/null 2>&1; then
  warn "Building image..."
  (cd "$SCRIPT_DIR" && $COMPOSE build) || err "Build failed"
fi

log "Project: $(pwd) -> /workspace"
case "${1:-}" in
  bash)   $COMPOSE -f "$COMPOSE_FILE" run --rm dev /bin/bash ;;
  build)  (cd "$SCRIPT_DIR" && $COMPOSE build --no-cache) ;;
  clean)  $COMPOSE -f "$COMPOSE_FILE" down --volumes; docker system prune -f ;;
  save-p10k) 
    log "Saving P10k configuration..."
    $COMPOSE -f "$COMPOSE_FILE" exec dev bash -c "
      if [ -f ~/.p10k.zsh ]; then
        mkdir -p /root/.p10k_persistent
        cp ~/.p10k.zsh /root/.p10k_persistent/.p10k.zsh
        echo 'P10k configuration saved!'
      else
        echo 'No P10k configuration found. Run p10k configure first.'
      fi
    " ;;
  info)   log "Image: 42-dev-env:latest | Compose: $COMPOSE_FILE | Use 'dev save-p10k' to save P10k settings" ;;
  *)      $COMPOSE -f "$COMPOSE_FILE" run --rm dev ;;
esac
EOF
  chmod +x "$DEV_ENV_DIR/dev"

  # Build the image
  info "Building image..."
  cd "$DEV_ENV_DIR"
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose build
  else
    docker-compose build
  fi
fi

# Add dev to PATH
if [[ ":$PATH:" != *":$DEV_ENV_DIR:"* ]]; then
  export PATH="$DEV_ENV_DIR:$PATH"
  case "$SHELL" in
    *zsh)  echo 'export PATH="$HOME/.docker-dev-env:$PATH"' >> ~/.zshrc ;;
    *bash) echo 'export PATH="$HOME/.docker-dev-env:$PATH"' >> ~/.bashrc ;;
  esac
fi

# Setup .devcontainer
info "Setting up .devcontainer..."
mkdir -p .devcontainer

curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/devcontainer.json -o .devcontainer/devcontainer.json
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/setup-gdb.sh -o .devcontainer/setup-gdb.sh
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/GDB_Help.md -o .devcontainer/GDB_Help.md
