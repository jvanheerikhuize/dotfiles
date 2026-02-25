FROM ubuntu:22.04

# Suppress interactive prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# Bootstrap dependencies
# install.sh pre-flight requires: git, python3
# YAML parsing requires: python3-yaml
# Passwordless sudo is required because install.sh rejects root but calls
# sudo internally for apt-get, snap, etc.
# ---------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        git \
        python3 \
        python3-yaml \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Non-root user with passwordless sudo
# install.sh has require_not_root() — must run as a regular user.
# ---------------------------------------------------------------------------
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser && \
    chmod 0440 /etc/sudoers.d/testuser

# ---------------------------------------------------------------------------
# Copy the repository into the image
# Build context is the repo root (passed by run-tests.sh).
# This bakes the exact working tree into the image — no network clone needed.
# ---------------------------------------------------------------------------
COPY --chown=testuser:testuser . /home/testuser/dotfiles

USER testuser
WORKDIR /home/testuser/dotfiles
