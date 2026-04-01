# Copyright (c) 2026 Sławomir Laskowski
# https://github.com/sshlio/dot
# Licensed under the MIT License. See LICENSE file for details.

FROM ubuntu:24.04

LABEL maintainer="Sławomir Laskowski"

RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install the current Neovim release.
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz \
    && tar -C /usr/local -xzf nvim-linux-arm64.tar.gz --strip-components=1 \
    && rm nvim-linux-arm64.tar.gz

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
