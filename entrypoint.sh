#!/bin/bash
set -e

setup_zshrc() {
    if [ ! -f /home/red/.zshrc ]; then
        touch /home/red/.zshrc
    fi
    if ! grep -qxF 'export PATH="/home/red/.local/bin:${PATH}"' /home/red/.zshrc; then
        echo 'export PATH="/home/red/.local/bin:${PATH}"' >> /home/red/.zshrc
    fi
}

setup_local_bin() {
    if [ ! -d /home/red/.local/bin ]; then
        mkdir -p /home/red/.local/bin
    fi
}

setup_vscode_cli() {
    redirect_url=$(curl -fsSLI "https://update.code.visualstudio.com/latest/cli-linux-x64/stable" | grep -i '^location:' | awk '{print $2}' | tr -d '\r\n')
    latest_version=$(echo "$redirect_url" | sed -E 's#.*/stable/([^/]+)/.*#\1#')
    installed_version=""
    if [ -f /home/red/.local/bin/code ]; then
        installed_version=$(/home/red/.local/bin/code --version | grep -oE '[a-f0-9]{40}' | head -n1)
    fi

    if [ ! -f /home/red/.local/bin/code ] || [ "$installed_version" != "$latest_version" ]; then
        echo "Updating VS Code CLI: installed=${installed_version:-none}, latest=${latest_version}"
        curl -fsSL "$redirect_url" -o /home/red/vscode-cli.tar.gz
        tar -xzf /home/red/vscode-cli.tar.gz -C /home/red
        rm /home/red/vscode-cli.tar.gz
        mv /home/red/code /home/red/.local/bin/code
        chmod +x /home/red/.local/bin/code
    else
        echo "VS Code CLI is up to date (version ${installed_version})."
    fi
}

setup_ssh() {
    if [ "${PRIVATE_KEY}" = "true" ]; then
        if [ ! -d /home/red/.ssh ]; then
            mkdir -p /home/red/.ssh
            chmod 700 /home/red/.ssh
        fi
        if [ ! -f /home/red/.ssh/id_rsa ]; then
            ssh-keygen -t rsa -b 4096 -f /home/red/.ssh/id_rsa -N ''
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
            chmod 700 /home/red/.ssh
        fi
        echo "${SSH_PRIVATE}" > /home/red/.ssh/id_rsa
        echo "${SSH_PUBLIC}" > /home/red/.ssh/id_rsa.pub
        chmod 600 /home/red/.ssh/id_rsa
        chmod 644 /home/red/.ssh/id_rsa.pub
        echo "********* SSH Key Injected Successfully *********"
        cat /home/red/.ssh/id_rsa.pub
        echo "*************************************************"
    fi
}

setup_git_config() {
    if [ -n "${GITHUB_USERNAME}" ]; then
        git config --global user.name "${GITHUB_USERNAME}"
    fi
    if [ -n "${GITHUB_EMAIL}" ]; then
        git config --global user.email "${GITHUB_EMAIL}"
    fi
}

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
        /home/red/.local/bin/code tunnel user login --provider "${PROVIDER}"
        touch /home/red/check && echo ${TUNNEL_NAME} > /home/red/check
    else
        echo "Tunnel already exists."
    fi

    /home/red/.local/bin/code tunnel --accept-server-license-terms --name "${TUNNEL_NAME}"
}

setup_zshrc
setup_local_bin
setup_vscode_cli
setup_ssh
setup_git_config
start_tunnel
