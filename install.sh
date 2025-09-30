#!/usr/bin/env bash

mkdir -p .devcontainer

curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/devcontainer.json -o .devcontainer/devcontainer.json
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/setup-gdb.sh -o .devcontainer/setup-gdb.sh
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/setup-shell.sh -o .devcontainer/setup-shell.sh
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/GDB_Help.md -o .devcontainer/GDB_Help.md