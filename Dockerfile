# Copyright (c) 2026 Sławomir Laskowski
# https://github.com/sshlio/dot
# Licensed under the MIT License. See LICENSE file for details.

FROM ubuntu:24.04

LABEL maintainer="Sławomir Laskowski"

ARG NVIM_VERSION=v0.10.0
ARG NODE_MAJOR=24
ARG NUSHELL_NPM_VERSION=0.111.0
ARG CLAUDE_CODE_NPM_VERSION=2.1.87
ARG AWS_SDK_NPM_VERSION=2.1693.0

RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Neovim from an explicit release so automation can update it safely.
RUN curl -LO https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-arm64.tar.gz \
    && tar -C /usr/local -xzf nvim-linux-arm64.tar.gz --strip-components=1 \
    && rm nvim-linux-arm64.tar.gz

# Install Node.js from a pinned major release channel.
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g \
    nushell@${NUSHELL_NPM_VERSION} \
    @anthropic-ai/claude-code@${CLAUDE_CODE_NPM_VERSION} \
    aws-sdk@${AWS_SDK_NPM_VERSION}

RUN useradd -m -s /usr/bin/nu billy

USER billy

WORKDIR /home/billy

RUN mkdir .config

COPY --chown=billy:billy nvim .config/nvim
COPY --chown=billy:billy nushell .config/nushell

RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"

ENTRYPOINT ["nu"]
