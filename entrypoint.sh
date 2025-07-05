#!/bin/bash
set -e

export PATH="/home/red/.local/bin:${PATH}"

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
    if [ "${PRIVATE_RSA}" = "true" ] || [ "${PRIVATE_ED}" = "true" ]; then
        if [ ! -d /home/red/.ssh ]; then
            mkdir -p /home/red/.ssh
            chmod 700 /home/red/.ssh
        fi
        if [ "${PRIVATE_RSA}" = "true" ]; then
            if [ ! -f /home/red/.ssh/id_rsa ]; then
                ssh-keygen -t rsa -b 4096 -f /home/red/.ssh/id_rsa -N ""
                chmod 600 /home/red/.ssh/id_rsa
                chmod 644 /home/red/.ssh/id_rsa.pub
                echo "********* Generated new RSA SSH keypair *********"
                echo "Public Key: $(cat /home/red/.ssh/id_rsa.pub)"
                echo "*************************************************"
                echo ""
            fi
        fi
        if [ "${PRIVATE_ED}" = "true" ]; then
            if [ ! -f /home/red/.ssh/id_ed25519 ]; then
                ssh-keygen -t ed25519 -f /home/red/.ssh/id_ed25519 -N ""
                chmod 600 /home/red/.ssh/id_ed25519
                chmod 644 /home/red/.ssh/id_ed25519.pub
                echo "********* Generated new ED25519 SSH keypair *********"
                echo "Public Key: $(cat /home/red/.ssh/id_ed25519.pub)"
                echo "*****************************************************"
                echo ""
            fi
        fi
    else
        echo "No SSH key generation requested. Skipping SSH key setup."
    fi

    if [ -n "${SSH_PRIVATE}" ] && [ -n "${SSH_PUBLIC}" ]; then
        if [ ! -d /home/red/.ssh ]; then
            echo "********* Creating .ssh directory *********"
            mkdir -p /home/red/.ssh
            chmod 700 /home/red/.ssh
        fi
        echo "${SSH_PRIVATE}" > /home/red/.ssh/id_private
        echo "${SSH_PUBLIC}" > /home/red/.ssh/id_public
        chmod 600 /home/red/.ssh/id_private
        chmod 644 /home/red/.ssh/id_public
        if [ -n "${DOCKER_HOST}" ]; then
            host=$(echo "${DOCKER_HOST}" | sed -E 's#ssh://([^@]+@)?([^:/]+).*#\2#')
            if [ -n "${host}" ] && ! grep -qE "^${host}[ ,]" /home/red/.ssh/known_hosts 2>/dev/null; then
                ssh-keyscan -H "${host}" >> /home/red/.ssh/known_hosts 2>/dev/null || true
                chmod 644 /home/red/.ssh/known_hosts
                echo "Added ${host} to known_hosts."
            fi
        fi
        eval "$(ssh-agent -s)"
        ssh-add -D >/dev/null 2>&1 || true
        ssh-add /home/red/.ssh/id_private
        echo "********* id_private key added to SSH agent *********"
        echo "********* SSH Key Injected Successfully *********"
        cat /home/red/.ssh/id_public
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

setup_chezmoi() {
    if [ -z "${CHEZMOI_REPO}" ] || [ -z "${CHEZMOI_BRANCH}" ]; then
        echo "CHEZMOI_REPO and CHEZMOI_BRANCH must be set for chezmoi setup."
        return 1
    fi
    if [ -n "${CHEZMOI_REPO}" ]; then
        echo "*** Setting up Chezmoi with repository ${CHEZMOI_REPO} on branch ${CHEZMOI_BRANCH}."
        if ! command -v chezmoi >/dev/null 2>&1; then
            echo "*** Installing chezmoi..."
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/red/.local/bin
            export PATH="/home/red/.local/bin:${PATH}"
            echo "*** Chezmoi Successfully Installed."
        else
            echo "*** Chezmoi already installed. Skipping installation."
        fi
        if [ -d "$HOME/.local/share/chezmoi" ]; then
            cd "$HOME/.local/share/chezmoi"
            git remote update >/dev/null 2>&1
            LOCAL=$(git rev-parse @)
            REMOTE=$(git rev-parse @{u})
            if [ "$LOCAL" != "$REMOTE" ]; then
                echo "*** Remote changes detected, running chezmoi update."
                chezmoi update --force --no-tty
            else
                echo "*** No remote changes detected, skipping chezmoi update."
            fi
            cd - >/dev/null
        else
            chezmoi init --no-tty --branch "$CHEZMOI_BRANCH" --apply "$CHEZMOI_REPO"
        fi
        echo "*** Chezmoi initialized with repository ${CHEZMOI_REPO} on branch ${CHEZMOI_BRANCH}."
    fi
}

send_discord_webhook() {
    local message="$1"
    echo "[INFO] Attempting to send Discord webhook with message:"
    echo "$message"
    if [ -n "${DISCORD_WEBHOOK_URL}" ]; then
        local response
        response=$(curl -s -w "%{http_code}" -H "Content-Type: application/json" \
            -X POST \
            -d "{\"content\": \"${message}\"}" \
            "${DISCORD_WEBHOOK_URL}" -o /dev/null)
        if [ "$response" = "204" ]; then
            echo "[INFO] Discord webhook sent successfully."
        else
            echo "[ERROR] Discord webhook failed with HTTP status: $response"
        fi
    else
        echo "[WARN] DISCORD_WEBHOOK_URL is not set. Skipping Discord notification."
    fi
}

start_tunnel() {
    local TUNNEL_NAME="${TUNNEL_NAME:-vscode-tunnel}"
    local PROVIDER="${PROVIDER:-github}"
    export PATH="/home/red/.local/bin:${PATH}"

    if [ -f /home/red/check ]; then
        local OLD_TUNNEL_NAME
        OLD_TUNNEL_NAME=$(cat /home/red/check)
        if [ "${OLD_TUNNEL_NAME}" != "${TUNNEL_NAME}" ]; then
            rm -f /home/red/.vscode/cli/token.json /home/red/.vscode/cli/code_tunnel.json
            echo "Removed old tunnel configuration."
        fi
    fi

    if [ ! -f /home/red/.vscode/cli/token.json ] || [ ! -f /home/red/.vscode/cli/code_tunnel.json ]; then
        echo "[INFO] No existing tunnel credentials found. Starting login..."
        /home/red/.local/bin/code tunnel user login --provider "${PROVIDER}" 2>&1 | while IFS= read -r line; do
            echo "$line"
            if echo "$line" | grep -q "microsoft.com/devicelogin"; then
                code=$(echo "$line" | grep -oE 'enter the code [A-Z0-9]+' | awk '{print $4}')
                url=$(echo "$line" | grep -oE 'https://microsoft.com/devicelogin')
                msg="VSCode Tunnel: Please login at ${url} with code \`${code}\`"
                echo "[INFO] $msg"
                send_discord_webhook "$msg"
            elif echo "$line" | grep -q "github.com/login/device"; then
                code=$(echo "$line" | grep -oE 'use code [A-Z0-9\-]+' | awk '{print $3}')
                url=$(echo "$line" | grep -oE 'https://github.com/login/device')
                msg="VSCode Tunnel: Please login at ${url} with code \`${code}\`"
                echo "[INFO] $msg"
                send_discord_webhook "$msg"
            fi
        done
        touch /home/red/check && echo "${TUNNEL_NAME}" > /home/red/check
    else
        echo "Tunnel already exists."
        echo "[INFO] Starting VSCode tunnel..."
        local tunnel_output
        tunnel_output=$(/home/red/.local/bin/code tunnel --accept-server-license-terms --name "${TUNNEL_NAME}" 2>&1)
        echo "$tunnel_output"
        if echo "$tunnel_output" | grep -q "https://vscode.dev/tunnel/"; then
            local link
            link=$(echo "$tunnel_output" | grep -oE 'https://vscode.dev/tunnel/[^ ]+')
            local msg="VSCode Tunnel is ready: ${link}"
            echo "[INFO] $msg"
            send_discord_webhook "$msg"
        elif echo "$tunnel_output" | grep -qi "error"; then
            echo "[ERROR] Tunnel failed to start."
            send_discord_webhook "VSCode Tunnel: Failed to start. Output: \`\`\`${tunnel_output}\`\`\`"
        fi
    fi
}

setup_zshrc
setup_local_bin
setup_vscode_cli
setup_ssh
setup_git_config
setup_chezmoi
start_tunnel
