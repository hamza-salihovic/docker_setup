#!/bin/bash

# Setup Shell Environment Script
# This script configures an enhanced shell environment for 42 school development
# Installs Oh My Zsh, Powerlevel10k, Neovim, and configures the shell properly

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Error occurred at line $line_number (exit code: $exit_code)"
    exit $exit_code
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Check if running as root (for package installations)
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root - will use direct package manager commands"
        SUDO=""
    else
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
            log_info "Will use sudo for package installations"
        else
            log_error "sudo not available and not running as root"
            exit 1
        fi
    fi
}

# Update package lists
update_packages() {
    log_info "Updating package lists..."

    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update -qq || {
            log_warning "Failed to update package lists, continuing anyway..."
        }
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum update -q || {
            log_warning "Failed to update package lists, continuing anyway..."
        }
    elif command -v apk >/dev/null 2>&1; then
        $SUDO apk update || {
            log_warning "Failed to update package lists, continuing anyway..."
        }
    else
        log_warning "Unknown package manager, skipping package update"
    fi
}

# Install basic dependencies
install_dependencies() {
    log_info "Installing basic dependencies..."

    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get install -y -qq git curl wget ca-certificates gnupg lsb-release software-properties-common build-essential || {
            log_error "Failed to install basic dependencies"
            exit 1
        }
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum install -y -q git curl wget ca-certificates gnupg build-essential || {
            log_error "Failed to install basic dependencies"
            exit 1
        }
    elif command -v apk >/dev/null 2>&1; then
        $SUDO apk add git curl wget ca-certificates gnupg build-base || {
            log_error "Failed to install basic dependencies"
            exit 1
        }
    else
        log_warning "Unknown package manager, assuming dependencies are available"
    fi

    log_success "Basic dependencies installed"
}

# Install Neovim
install_neovim() {
    log_info "Installing Neovim..."

    # Check if already installed
    if command -v nvim >/dev/null 2>&1; then
        local version=$(nvim --version | head -n1)
        log_info "Neovim already installed: $version"
        return 0
    fi

    # Install Neovim using official installer
    if command -v apt-get >/dev/null 2>&1; then
        # Try official Neovim repository first
        if ! $SUDO apt-get install -y -qq neovim; then
            log_warning "Failed to install Neovim from official repo, trying alternative method"
            # Fallback to AppImage or build from source
            install_neovim_appimage
        fi
    elif command -v yum >/dev/null 2>&1; then
        # For RHEL/CentOS systems
        $SUDO yum install -y -q neovim || install_neovim_appimage
    else
        install_neovim_appimage
    fi

    # Verify installation
    if command -v nvim >/dev/null 2>&1; then
        local version=$(nvim --version | head -n1)
        log_success "Neovim installed: $version"
    else
        log_error "Neovim installation failed"
        exit 1
    fi
}

# Install Neovim as AppImage (fallback method)
install_neovim_appimage() {
    log_info "Installing Neovim as AppImage..."

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Download latest Neovim AppImage
    wget -q https://github.com/neovim/neovim/releases/latest/download/nvim.appimage || {
        log_error "Failed to download Neovim AppImage"
        cd - > /dev/null
        rm -rf "$temp_dir"
        exit 1
    }

    # Make executable and move to PATH
    chmod +x nvim.appimage
    $SUDO mv nvim.appimage /usr/local/bin/nvim

    cd - > /dev/null
    rm -rf "$temp_dir"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    log_info "Installing Oh My Zsh..."

    # Check if already installed
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh already installed"
        return 0
    fi

    # Install Oh My Zsh
    if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        log_error "Failed to install Oh My Zsh"
        exit 1
    fi

    log_success "Oh My Zsh installed"
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    log_info "Installing Powerlevel10k theme..."

    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    # Check if already installed
    if [[ -d "$p10k_dir" ]]; then
        log_info "Powerlevel10k already installed"
        return 0
    fi

    # Install Powerlevel10k
    if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"; then
        log_error "Failed to install Powerlevel10k theme"
        exit 1
    fi

    log_success "Powerlevel10k theme installed"
}

# Configure shell environment
configure_shell() {
    log_info "Configuring shell environment..."

    # Backup existing .zshrc if it exists and is not already enhanced
    if [[ -f "$HOME/.zshrc" ]] && ! grep -q "42-enhanced-zsh" "$HOME/.zshrc"; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing .zshrc"
    fi

    # Create enhanced .zshrc configuration
    cat >> "$HOME/.zshrc" << 'EOF'

# 42-enhanced-zsh configuration
# This section added by setup-shell.sh

# Enable Powerlevel10k theme if available
if [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
fi

# Enhanced PATH for 42 development
export PATH="$HOME/.local/bin:$PATH"

# 42-specific environment variables
export USER=$(whoami)
export MAIL="$USER@student.42.fr"

# History configuration
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000
export HISTCONTROL=ignoredups:ignorespace

# Enable autocorrect but not for certain commands
ENABLE_CORRECTION="true"

# Display red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

# Disable marking untracked files as dirty in VCS
DISABLE_UNTRACKED_FILES_DIRTY="true"

# 42-specific aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases for 42 workflow
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Neovim alias
alias vim='nvim'
alias vi='nvim'

# 42-specific functions
norminette_check() {
    if command -v norminette >/dev/null 2>&1; then
        norminette "$1"
    else
        echo "Norminette not installed. Install with: python3 -m pip install norminette"
    fi
}

# Quick compilation for C projects
compile_c() {
    local file="$1"
    local output="${file%.c}"
    gcc -Wall -Wextra -Werror "$file" -o "$output" && echo "Compiled $output successfully"
}

# Quick compilation for C++ projects
compile_cpp() {
    local file="$1"
    local output="${file%.cpp}"
    g++ -Wall -Wextra -Werror -std=c++98 "$file" -o "$output" && echo "Compiled $output successfully"
}

# Function to quickly create a new C project structure
new_c_project() {
    local project_name="$1"
    mkdir -p "$project_name"
    cd "$project_name"
    touch "$project_name.c" Makefile README.md
    echo "Created C project structure for $project_name"
}

# Function to quickly create a new C++ project structure
new_cpp_project() {
    local project_name="$1"
    mkdir -p "$project_name"
    cd "$project_name"
    touch "$project_name.cpp" Makefile README.md
    echo "Created C++ project structure for $project_name"
}

# Load Powerlevel10k configuration if available
if [[ -f ~/.p10k.zsh ]]; then
    source ~/.p10k.zsh
fi

# Load Oh My Zsh
if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
fi

# Welcome message
echo "42 Enhanced Zsh Environment Loaded!"
echo "Available aliases: ll, la, l, .., ..., gs, ga, gc, gp, gl, gd, gco, gb"
echo "Available functions: norminette_check, compile_c, compile_cpp, new_c_project, new_cpp_project"
echo "Use 'p10k configure' to customize Powerlevel10k theme"

EOF

    log_success "Shell environment configured"
}

# Set proper permissions
set_permissions() {
    log_info "Setting proper permissions..."

    # Ensure .zshrc is readable and writable by user only
    chmod 644 "$HOME/.zshrc"

    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"

    # Set proper ownership if running as root
    if [[ $EUID -eq 0 ]]; then
        chown -R "$(stat -c '%u:%g' "$HOME" 2>/dev/null || echo "$USER:$USER")" "$HOME"
    fi

    log_success "Permissions set"
}

# Main installation function
main() {
    log_info "Starting shell environment setup..."

    # Check sudo availability
    check_sudo

    # Update packages
    update_packages

    # Install dependencies
    install_dependencies

    # Install Neovim
    install_neovim

    # Install Oh My Zsh
    install_oh_my_zsh

    # Install Powerlevel10k
    install_powerlevel10k

    # Configure shell
    configure_shell

    # Set permissions
    set_permissions

    log_success "Shell environment setup completed!"
    log_info "Please restart your shell or run 'source ~/.zshrc' to apply changes"
    log_info "You can customize Powerlevel10k by running 'p10k configure' in your terminal"
}

# Run main function
main "$@"