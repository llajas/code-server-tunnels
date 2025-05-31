#!/bin/bash
set -e

setup_permissions() {
    chmod g+w /home/red
    chgrp -R 0 /home/red
    chmod -R g=u /home/red
    if [ ! -d /home/red ]; then
        mkdir -p /home/red
        chown red:red /home/red
    fi
    chown -R red:red /home/red
}

setup_zshrc() {
    if [ ! -f /home/red/.zshrc ]; then
        touch /home/red/.zshrc
        chown red:red /home/red/.zshrc
    fi
    if ! grep -qxF 'export PATH="/home/red/.local/bin:${PATH}"' /home/red/.zshrc; then
        echo 'export PATH="/home/red/.local/bin:${PATH}"' >> /home/red/.zshrc
    fi
}

setup_local_bin() {
    if [ ! -d /home/red/.local/bin ]; then
        mkdir -p /home/red/.local/bin
        chown -R red:red /home/red/.local
    fi
    if [ ! -f /home/red/.local/bin/code ]; then
        curl -fsSL "https://update.code.visualstudio.com/latest/cli-linux-x64/stable" \
            -o /home/red/vscode-cli.tar.gz
        tar -xzf /home/red/vscode-cli.tar.gz -C /home/red
        rm /home/red/vscode-cli.tar.gz
        mv /home/red/code /home/red/.local/bin/code
        chmod +x /home/red/.local/bin/code
        chown red:red /home/red/.local/bin/code
    fi
}

########## CUSTOMIZATIONS ##########

setup_ssh() {
    if [ "${PRIVATE_KEY}" = "true" ]; then
        if [ ! -d /home/red/.ssh ]; then
            mkdir -p /home/red/.ssh
            chown red:red /home/red/.ssh
            chmod 700 /home/red/.ssh
        fi
        if [ ! -f /home/red/.ssh/id_rsa ]; then
            su red -c "ssh-keygen -t rsa -b 4096 -f /home/red/.ssh/id_rsa -N ''"
            chown red:red /home/red/.ssh/id_rsa
            chown red:red /home/red/.ssh/id_rsa.pub
            chmod 600 /home/red/.ssh/id_rsa
            chmod 644 /home/red/.ssh/id_rsa.pub
            echo "********* SSH Key Generated Successfully **********"
            cat /home/red/.ssh/id_rsa.pub
            echo "***************************************************"
        fi
    fi

    if [ -n "${SSH_PRIVATE}" ] && [ -n "${SSH_PUBLIC}" ]; then
        if [ ! -d /home/red/.ssh ]; then
            mkdir -p /home/red/.ssh
            chown red:red /home/red/.ssh
            chmod 700 /home/red/.ssh
        fi
        echo "${SSH_PRIVATE}" > /home/red/.ssh/id_rsa
        echo "${SSH_PUBLIC}" > /home/red/.ssh/id_rsa.pub
        chown red:red /home/red/.ssh/id_rsa /home/red/.ssh/id_rsa.pub
        chmod 600 /home/red/.ssh/id_rsa
        chmod 644 /home/red/.ssh/id_rsa.pub
        echo "********* SSH Key Injected Successfully **********"
        cat /home/red/.ssh/id_rsa.pub
        echo "*************************************************"
    fi
}

setup_docker() {
    if [ -n "${DOCKER_HOST}" ]; then
        docker_host_ip=$(echo "${DOCKER_HOST}" | sed -n 's/.*@\(.*\)/\1/p' | sed 's#/.*##')
        echo "Setting up Docker with host ${docker_host_ip}"
        if ! command -v docker &>/dev/null; then
            echo "Docker CLI not found. Installing docker as red..."
            su red -c 'sudo apt-get update'
            su red -c 'sudo apt-get install -y docker.io'
        else
            echo "Docker CLI is available."
        fi
        if ! getent group docker >/dev/null; then
            groupadd docker
        fi
        if ! id -nG red | grep -qw docker; then
            usermod -aG docker red
            echo "Added red to docker group"
        fi
        if [ "${DOCKER_COMPOSE}" = "true" ]; then
            if ! command -v docker-compose &>/dev/null; then
                su red -c 'sudo apt-get update'
                su red -c 'sudo apt-get install -y ca-certificates curl gnupg lsb-release'
                su red -c 'sudo mkdir -p /etc/apt/keyrings'
                su red -c 'curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg'
                su red -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
                su red -c 'sudo apt-get update'
                su red -c 'sudo apt-get install -y docker-compose-plugin'
            else
                echo "Docker Compose is already installed."
            fi
        else
            echo "Skipping Docker Compose Install."
        fi
        if [ -n "${docker_host_ip}" ]; then
            if ! grep -q "${docker_host_ip}" /home/red/.ssh/known_hosts 2>/dev/null; then
                if [ ! -d /home/red/.ssh ]; then
                    mkdir -p /home/red/.ssh
                    chown red:red /home/red/.ssh
                    chmod 700 /home/red/.ssh
                fi
                ssh-keyscan -H "${docker_host_ip}" >> /home/red/.ssh/known_hosts 2>/dev/null
                chown red:red /home/red/.ssh/known_hosts
                chmod 644 /home/red/.ssh/known_hosts
                echo "Added ${docker_host_ip} to known_hosts"
            fi
        fi
    fi
}

setup_git_config() {
    if [ -n "${GIT_USER_NAME}" ]; then
        su red -c "git config --global user.name '${GIT_USER_NAME}'"
    fi
    if [ -n "${GIT_USER_EMAIL}" ]; then
        su red -c "git config --global user.email '${GIT_USER_EMAIL}'"
    fi
}

####################################


start_tunnel() {
    local TUNNEL_NAME="${TUNNEL_NAME:-vscode-tunnel}"
    local PROVIDER="${PROVIDER:-github}"
    export PATH="/home/red/.local/bin:${PATH}"

    if [ -f /home/red/check ]; then
        local OLD_TUNNEL_NAME=$(cat /home/red/check)
        if [ "${OLD_TUNNEL_NAME}" != "${TUNNEL_NAME}" ]; then
            rm -f /home/red/.vscode/cli/token.json /home/red/.vscode/cli/code_tunnel.json
            echo "Removed old tunnel configuration."
        fi
    fi

    if [ ! -f /home/red/.vscode/cli/token.json ] || [ ! -f /home/red/.vscode/cli/code_tunnel.json ]; then
        su red -c "export HOME=/home/red; /home/red/.local/bin/code tunnel user login --provider '${PROVIDER}'"
        su red -c "touch /home/red/check && echo ${TUNNEL_NAME} > /home/red/check"
        chown red:red /home/red/check
    else
        echo "Tunnel already exists."
    fi

    su red -c "export HOME=/home/red; /home/red/.local/bin/code tunnel --accept-server-license-terms --name '${TUNNEL_NAME}'"
}

setup_permissions
setup_zshrc
setup_local_bin
#### CUSTOMIZATIONS ####
setup_ssh
setup_docker
setup_git_config
########################
start_tunnel
