#!/usr/bin/env bash

mkdir -p .devcontainer

curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/Dockerfile?token=GHSAT0AAAAAAC5FHS45U65IHQEOQNEU4YNQ2DBCKMA -o .devcontainer/Dockerfile
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/devcontainer.json?token=GHSAT0AAAAAAC5FHS45FWTUV35BS7YRIV242DBCK4Q -o .devcontainer/devcontainer.json
curl -fsSL https://raw.githubusercontent.com/hamza-salihovic/docker_setup/refs/heads/main/setup-gdb.sh?token=GHSAT0AAAAAAC5FHS45D3CZ6NQYQAXAHBLS2DBCTTA -o .devcontainer/setup-gdb.sh
