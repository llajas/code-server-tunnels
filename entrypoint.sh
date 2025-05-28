#!/bin/bash
TUNNEL_NAME="${TUNNEL_NAME:-vscode-tunnel}" # Default tunnel name if not set
PROVIDER="${PROVIDER:-microsoft}" # Default provider if not set

curl -fsSL "https://update.code.visualstudio.com/latest/cli-linux-x64/stable" \
    -o /home/coder/vscode-cli.tar.gz \
  && tar -xzf /home/coder/vscode-cli.tar.gz -C /home/coder \
  && rm /home/coder/vscode-cli.tar.gz \
  && mkdir -p /home/coder/.local/bin \
  && mv /home/coder/code /home/coder/.local/bin/code

# Append PATH to .bashrc if not already present
grep -qxF 'export PATH="/home/coder/.local/bin:${PATH}"' /home/coder/.bashrc || echo 'export PATH="/home/coder/.local/bin:${PATH}"' >> /home/coder/.bashrc

# Source .bashrc to make the new PATH available in this script's session
# or simply set it for the current script execution
export PATH="/home/coder/.local/bin:${PATH}"

code tunnel user login --provider ${PROVIDER}
code tunnel --accept-server-license-terms --name "${TUNNEL_NAME}"