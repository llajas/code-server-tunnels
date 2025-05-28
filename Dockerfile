FROM debian:bullseye-slim

# Install minimal dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    sudo \
  && rm -rf /var/lib/apt/lists/*

# Create a non-root user and add to sudoers
# This creates /home/coder owned by coder and populates it from /etc/skel
RUN useradd -m -s /bin/bash coder \
  && echo "coder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Copy entrypoint script. It will be owned by coder:coder.
# The script is placed in /home/coder for simplicity.
COPY --chown=coder:coder entrypoint.sh /tmp/entrypoint.sh

# Switch to the coder user
USER coder
WORKDIR /home/coder

# Ensure entrypoint is executable by the coder user
# This RUN command executes as 'coder'
RUN chmod +x /tmp/entrypoint.sh

# Default entrypoint
CMD ["/bin/bash", "/tmp/entrypoint.sh"]