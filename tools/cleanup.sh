#!/bin/bash

# Ensure a clean environment by stopping and removing everything related to Podman

echo "Cleaning up Podman environment..."

# Stop and remove ALL containers (internal and external)
echo "Stopping and removing all containers..."
podman stop -f $(podman ps -a --format "{{.ID}}") 2>/dev/null
podman stop -f $(podman ps -a --external --format "{{.ID}}") 2>/dev/null
podman rm -f $(podman ps -a --format "{{.ID}}") 2>/dev/null
podman rm -f $(podman ps -a --external --format "{{.ID}}") 2>/dev/null

# Unmount any remaining mounted containers
echo "Unmounting any mounted containers..."
podman unmount $(podman ps -a --format "{{.ID}}") 2>/dev/null
podman unmount $(podman ps -a --external --format "{{.ID}}") 2>/dev/null

# Remove ALL images (used, unused, dangling)
echo "Removing all images..."
podman rmi -f $(podman images -q) 2>/dev/null

# Remove ALL volumes
echo "Removing all volumes..."
podman volume rm -f $(podman volume ls -q) 2>/dev/null

# Remove ALL networks
echo "Removing all networks..."
podman network rm $(podman network ls -q) 2>/dev/null

# Prune ALL unused data (force prune with volumes)
echo "Pruning unused data..."
podman system prune -a -f --volumes 2>/dev/null

echo "Environment cleaned successfully."