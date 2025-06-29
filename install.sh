#!/usr/bin/env bash

mkdir -p .devcontainer

curl -fsSL https://github.com/hamza-salihovic/docker_setup/blob/89c99217a307c95c097fcec5b70c2e9aa985d642/Dockerfile -o .devcontainer/Dockerfile
curl -fsSL https://github.com/hamza-salihovic/docker_setup/blob/89c99217a307c95c097fcec5b70c2e9aa985d642/devcontainer.json -o .devcontainer/devcontainer.json