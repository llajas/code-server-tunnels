#!/bin/bash
IMAGE="brimdor/vscode-tunnel"

read -p "Docker.io Username: " DOCKER_USER
read -s -p "Docker.io Password: " DOCKER_PASS
echo

echo "$DOCKER_PASS" | podman login docker.io -u "$DOCKER_USER" --password-stdin

if [ $? -ne 0 ]; then
  echo "Docker login failed. Exiting."
  exit 1
fi

echo "Building and pushing image..."
podman build --no-cache -f Dockerfile -t $IMAGE .
podman push $IMAGE

echo "Script finished."