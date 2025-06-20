FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    sudo \
    zsh \
    openssh-client \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/zsh red \
  && echo "red ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER red
WORKDIR /home/red

COPY --chown=red:red entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0555 /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
