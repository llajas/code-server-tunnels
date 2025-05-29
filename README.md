# CODE SERVER TUNNELS

## Overview

`code-server-tunnels` is a Docker image designed to run VS Code in the browser using the VS Code CLI tunnel feature. It supports SSH key injection and Docker CLI integration.

---

## Usage

### Running with Docker

```sh
docker run -it \
  -e TUNNEL_NAME=my-tunnel \
  -e PROVIDER={microsoft or github} \
  -e PRIVATE_KEY=true \
  -e SSH_PRIVATE={secret} \
  -e SSH_PUBLIC={secret} \
  -e DOCKER_HOST=ssh://user@host \
  {registry/repository:version}
```

### With Helm or Kubernetes

Set the environment variables in your `values.yaml` or Pod spec under `env:` as shown above.

---

## Environment Variables

| Variable         | Required | Description |
|------------------|----------|-------------|
| `TUNNEL_NAME`    | No       | Name for the VS Code tunnel. Default: `vscode-tunnel` |
| `PROVIDER`       | No       | Tunnel provider. Default: `microsoft` |
| `PRIVATE_KEY`    | No       | If `true`, auto-generates an SSH key for the `coder` user. |
| `SSH_PRIVATE`    | No       | The private SSH key to inject into `/home/coder/.ssh/id_rsa`. |
| `SSH_PUBLIC`     | No       | The public SSH key to inject into `/home/coder/.ssh/id_rsa.pub`. |
| `DOCKER_HOST`    | No       | Docker host to connect to, e.g. `ssh://user@host`. If set, Docker CLI is installed and the host's SSH key is added to `known_hosts`. |

---

## Features

- Automatic VS Code tunnel setup
- SSH key generation or injection
- Docker CLI installation and setup
- Known hosts management for remote Docker hosts

---

## Example Helm values.yaml

```yaml
env:
  - name: TUNNEL_NAME
    value: my-tunnel
  - name: PROVIDER
    value: microsoft
  - name: PRIVATE_KEY
    value: "true"
  - name: SSH_PRIVATE
    valueFrom:
      secretKeyRef:
        name: my-ssh-secret
        key: id_rsa
  - name: SSH_PUBLIC
    valueFrom:
      secretKeyRef:
        name: my-ssh-secret
        key: id_rsa.pub
  - name: DOCKER_HOST
    value: ssh://user@host
  - name: DOCKER
    value: "true"
```

---

## Notes

- This image is built to be non-root. In order to use Docker, you must utilize a remote Docker setup.
- For remote Docker, ensure the host is reachable and SSH keys are valid.
- For Kubernetes/Helm, mount secrets for SSH keys as needed.
