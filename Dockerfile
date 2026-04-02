# Copyright (c) 2026 Sławomir Laskowski
# https://github.com/sshlio/dot
# Licensed under the MIT License. See LICENSE file for details.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

LABEL maintainer="Sławomir Laskowski"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    gnupg \
    unzip \
    lsb-release \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
        amd64) aws_arch="x86_64" ;; \
        arm64) aws_arch="aarch64" ;; \
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac \
    && curl -fsSLo awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install the current Terraform release.
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Install the current Neovim release.
RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
        amd64) nvim_arch="x86_64" ;; \
        arm64) nvim_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac \
    && curl -fLo nvim-linux.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" \
    && tar -C /usr/local -xzf nvim-linux.tar.gz --strip-components=1 \
    && rm nvim-linux.tar.gz

# Install the current Node.js release channel.
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g \
    nushell \
    @anthropic-ai/claude-code \
    aws-sdk

RUN useradd -m -s /usr/bin/nu billy

USER billy

WORKDIR /home/billy

RUN mkdir .config

COPY --chown=billy:billy nvim .config/nvim
COPY --chown=billy:billy nushell .config/nushell

RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"

ENTRYPOINT ["nu"]
