# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    Docker Development Environment                  +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/01/01 00:00:00 by docker        #+#    #+#              #
#    Updated: 2024/01/01 00:00:00 by docker       ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Colors for output
RED		= \033[0;31m
GREEN	= \033[0;32m
YELLOW	= \033[0;33m
BLUE	= \033[0;34m
PURPLE	= \033[0;35m
CYAN	= \033[0;36m
WHITE	= \033[0;37m
RESET	= \033[0m

# Default platform
PLATFORM ?= arm64

# Docker compose command
DC = docker-compose
DOCKER = docker

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help init build up down shell test clean fclean re norm format debug \
        build-arm build-x86 test-x86 stats logs prune update

# Help command
help: ## Show this help message
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(BLUE)║$(WHITE)          42 Docker Development Environment - Makefile         $(BLUE)║$(RESET)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(YELLOW)Available commands:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(PURPLE)Platform: $(PLATFORM) (change with PLATFORM=amd64 make <command>)$(RESET)"

# Initialize the Docker environment
init: ## Initialize Docker environment (first time setup)
	@echo "$(YELLOW)🚀 Initializing Docker environment...$(RESET)"
	@bash scripts/docker-init.sh
	@echo "$(GREEN)✅ Initialization complete!$(RESET)"

# Build Docker images
build: ## Build Docker image for current platform
	@echo "$(YELLOW)🔨 Building Docker image for $(PLATFORM)...$(RESET)"
	@$(DOCKER) buildx build \
		--platform linux/$(PLATFORM) \
		--tag 42-dev:$(PLATFORM) \
		--cache-from type=local,src=/tmp/.buildx-cache \
		--cache-to type=local,dest=/tmp/.buildx-cache,mode=max \
		--load \
		-f Dockerfile.optimized .
	@echo "$(GREEN)✅ Build complete!$(RESET)"

build-arm: ## Build ARM64 Docker image
	@$(MAKE) build PLATFORM=arm64

build-x86: ## Build x86_64 Docker image
	@$(MAKE) build PLATFORM=amd64

# Start containers
up: ## Start development container
	@echo "$(YELLOW)🚀 Starting development container ($(PLATFORM))...$(RESET)"
	@$(DC) up -d dev
	@echo "$(GREEN)✅ Container started!$(RESET)"
	@echo "$(CYAN)Run 'make shell' to enter the container$(RESET)"

# Stop containers
down: ## Stop and remove containers
	@echo "$(YELLOW)⏹️  Stopping containers...$(RESET)"
	@$(DC) down
	@echo "$(GREEN)✅ Containers stopped!$(RESET)"

# Enter container shell
shell: ## Enter development container shell
	@echo "$(CYAN)🐚 Entering container shell...$(RESET)"
	@bash scripts/docker-dev.sh $(PLATFORM)

# Run tests
test: ## Run tests in x86_64 container (campus compatibility)
	@echo "$(YELLOW)🧪 Running tests...$(RESET)"
	@bash scripts/docker-test.sh

test-x86: test ## Alias for test (x86_64 testing)

# Clean build artifacts
clean: ## Clean build artifacts and cache
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(RESET)"
	@$(DOCKER) run --rm \
		-v $(PWD):/workspace:cached \
		--platform linux/$(PLATFORM) \
		42-dev:$(PLATFORM) \
		/bin/bash -c "cd /workspace && rm -rf *.o *.a *.out build/ obj/"
	@echo "$(GREEN)✅ Clean complete!$(RESET)"

# Deep clean including Docker resources
fclean: clean down ## Full clean including Docker volumes
	@echo "$(RED)🗑️  Removing Docker volumes...$(RESET)"
	@$(DOCKER) volume rm -f ccache-data build-cache test-results analysis-reports 2>/dev/null || true
	@echo "$(GREEN)✅ Full clean complete!$(RESET)"

# Rebuild everything
re: fclean build ## Full rebuild (clean + build)
	@echo "$(GREEN)✅ Full rebuild complete!$(RESET)"

# Run norminette
norm: ## Run norminette on C files
	@echo "$(YELLOW)📏 Running norminette...$(RESET)"
	@$(DOCKER) run --rm \
		-v $(PWD):/workspace:ro \
		--platform linux/$(PLATFORM) \
		42-dev:$(PLATFORM) \
		/bin/bash -c "cd /workspace && norminette *.c *.h 2>/dev/null || echo 'No C files found'"

# Format code
format: ## Format C code with 42 formatter
	@echo "$(YELLOW)✨ Formatting code...$(RESET)"
	@$(DOCKER) run --rm \
		-v $(PWD):/workspace:cached \
		--platform linux/$(PLATFORM) \
		42-dev:$(PLATFORM) \
		/bin/bash -c "cd /workspace && c_formatter_42 *.c *.h 2>/dev/null || echo 'No C files found'"

# Debug with GDB
debug: ## Start debugging session with GDB
	@echo "$(CYAN)🐛 Starting GDB debug session...$(RESET)"
	@$(DOCKER) run --rm -it \
		-v $(PWD):/workspace:cached \
		--platform linux/$(PLATFORM) \
		--cap-add=SYS_PTRACE \
		--security-opt seccomp=unconfined \
		42-dev:$(PLATFORM) \
		/bin/bash -c "cd /workspace && gdb ./a.out"

# Show ccache statistics
stats: ## Show compiler cache statistics
	@echo "$(BLUE)📊 Compiler cache statistics:$(RESET)"
	@$(DOCKER) run --rm \
		-v ccache-data:/cache/ccache \
		--platform linux/$(PLATFORM) \
		42-dev:$(PLATFORM) \
		ccache -s

# Show container logs
logs: ## Show container logs
	@$(DC) logs -f --tail=50

# Prune Docker system
prune: ## Clean up Docker system (removes unused data)
	@echo "$(YELLOW)🧹 Pruning Docker system...$(RESET)"
	@$(DOCKER) system prune -f
	@$(DOCKER) buildx prune -f
	@echo "$(GREEN)✅ Prune complete!$(RESET)"

# Update Docker images
update: ## Pull latest base images and rebuild
	@echo "$(YELLOW)⬆️  Updating Docker images...$(RESET)"
	@$(DOCKER) pull ubuntu:22.04
	@$(MAKE) build PLATFORM=$(PLATFORM)
	@echo "$(GREEN)✅ Update complete!$(RESET)"

# Quick compile for testing
cc: ## Quick compile all .c files
	@echo "$(YELLOW)⚡ Quick compile...$(RESET)"
	@$(DOCKER) run --rm \
		-v $(PWD):/workspace:cached \
		--platform linux/$(PLATFORM) \
		42-dev:$(PLATFORM) \
		/bin/bash -c "cd /workspace && gcc -Wall -Wextra -Werror *.c -o program 2>/dev/null && echo '✅ Compilation successful' || echo '❌ Compilation failed'"

# Valgrind memory check
valgrind: ## Run valgrind memory check
	@echo "$(YELLOW)🔍 Running valgrind...$(RESET)"
	@$(DOCKER) run --rm \
		-v $(PWD):/workspace:cached \
		--platform linux/$(PLATFORM) \
		42-dev:$(PLATFORM) \
		/bin/bash -c "cd /workspace && valgrind --leak-check=full --show-leak-kinds=all ./a.out"