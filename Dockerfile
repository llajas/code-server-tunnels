FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    sudo \
    zsh \
    openssh-client \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash coder \
  && echo "coder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN chsh -s /bin/zsh coder

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0555 /usr/local/bin/entrypoint.sh

WORKDIR /home/coder

CMD ["/usr/local/bin/entrypoint.sh"]
