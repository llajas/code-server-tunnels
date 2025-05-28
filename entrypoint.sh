#!/bin/bash
set -e

setup_permissions() {
    chmod g+w /home/coder
    chgrp -R 0 /home/coder
    chmod -R g=u /home/coder
    if [ ! -d /home/coder ]; then
        mkdir -p /home/coder
        chown coder:coder /home/coder
    fi
    chown -R coder:coder /home/coder
}

setup_bashrc() {
    if [ ! -f /home/coder/.bashrc ]; then
        touch /home/coder/.bashrc
        chown coder:coder /home/coder/.bashrc
    fi
    if ! grep -qxF 'export PATH="/home/coder/.local/bin:${PATH}"' /home/coder/.bashrc; then
        echo 'export PATH="/home/coder/.local/bin:${PATH}"' >> /home/coder/.bashrc
    fi
}

setup_local_bin() {
    if [ ! -d /home/coder/.local/bin ]; then
        mkdir -p /home/coder/.local/bin
        chown -R coder:coder /home/coder/.local
    fi
    if [ ! -f /home/coder/.local/bin/code ]; then
        curl -fsSL "https://update.code.visualstudio.com/latest/cli-linux-x64/stable" \
            -o /home/coder/vscode-cli.tar.gz
        tar -xzf /home/coder/vscode-cli.tar.gz -C /home/coder
        rm /home/coder/vscode-cli.tar.gz
        mv /home/coder/code /home/coder/.local/bin/code
        chmod +x /home/coder/.local/bin/code
        chown coder:coder /home/coder/.local/bin/code
    fi
}

########## CUSTOMIZATIONS ##########

generate_ssh_key() {
    if [ "${PRIVATE_KEY}" = "true" ]; then
        if [ ! -d /home/coder/.ssh ]; then
            mkdir -p /home/coder/.ssh
            chown coder:coder /home/coder/.ssh
            chmod 700 /home/coder/.ssh
        fi
        if [ ! -f /home/coder/.ssh/id_rsa ]; then
            su coder -c "ssh-keygen -t rsa -b 4096 -f /home/coder/.ssh/id_rsa -N ''"
            chown coder:coder /home/coder/.ssh/id_rsa
            chown coder:coder /home/coder/.ssh/id_rsa.pub
            echo "********* SSH Key Generated Successfully **********"
            cat /home/coder/.ssh/id_rsa.pub
            echo "***************************************************"
        fi
    fi
}

setup_podman() {
    if [ "${PODMAN}" = "true" ]; then
        if ! command -v podman &>/dev/null; then
            echo "Podman CLI not found. Please install podman in the Dockerfile."
        else
            echo "Podman CLI is available."
        fi
        # Optionally, check for the socket
        if [ ! -S /run/podman/podman.sock ]; then
            echo "Warning: Podman socket not found. Mount it from the host if you want to use host podman."
        fi
    fi
}

setup_docker() {
    if [ "${DOCKER}" = "true" ]; then
        if ! command -v docker &>/dev/null; then
            echo "Docker CLI not found. Please install docker.io in the Dockerfile."
        else
            echo "Docker CLI is available."
        fi
        # Optionally, check for the socket
        if [ ! -S /var/run/docker.sock ]; then
            echo "Warning: Docker socket not found. Mount it from the host if you want to use host docker."
        fi
    fi
}


####################################


start_tunnel() {
    local TUNNEL_NAME="${TUNNEL_NAME:-vscode-tunnel}"
    local PROVIDER="${PROVIDER:-microsoft}"
    export PATH="/home/coder/.local/bin:${PATH}"

    if [ ! -f /home/coder/.vscode/cli/token.json ] || [ ! -f /home/coder/.vscode/cli/code_tunnel.json ]; then
        su coder -c "export HOME=/home/coder; /home/coder/.local/bin/code tunnel user login --provider '${PROVIDER}'"
        su coder -c "export HOME=/home/coder; /home/coder/.local/bin/code tunnel --accept-server-license-terms --name '${TUNNEL_NAME}'"
    else
        echo "Tunnel already exists."
        su coder -c "export HOME=/home/coder; /home/coder/.local/bin/code tunnel --accept-server-license-terms --name '${TUNNEL_NAME}'"
    fi
}

setup_permissions
setup_bashrc
setup_local_bin
#### CUSTOMIZATIONS ####
generate_ssh_key
setup_podman
setup_docker
########################
start_tunnel