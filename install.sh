#!/usr/bin/env bash

mkdir -p .devcontainer

curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/Dockerfile -o .devcontainer/Dockerfile
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/devcontainer.json -o .devcontainer/devcontainer.json
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/setup-gdb.sh -o .devcontainer/setup-gdb.sh
