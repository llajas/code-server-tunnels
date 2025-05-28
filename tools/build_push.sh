#!/bin/bash

# Prompt for Docker Hub credentials
read -p "Docker.io Username: " DOCKER_USER
read -s -p "Docker.io Password: " DOCKER_PASS
echo

# Login to Docker Hub
echo "$DOCKER_PASS" | podman login docker.io -u "$DOCKER_USER" --password-stdin

# Check if login was successful
if [ $? -ne 0 ]; then
  echo "Docker login failed. Exiting."
  exit 1
fi

echo "Building and pushing image..."
podman build -f Dockerfile -t brimdor/vscode-tunnel .
podman push brimdor/vscode-tunnel

echo "Script finished."