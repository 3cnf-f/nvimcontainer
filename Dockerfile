FROM ubuntu:latest

ENV LANG=C.UTF-8 \
    TERM=xterm-256color \
    TZ=Europe/Stockholm \
    DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.local/bin:$PATH" \
    # Defaults (can be overridden by podman run -e)
    TMP_GITUSER="temp_dev@example.com" \
    GH_TOKEN=""

# 1. Base Dependencies & GitHub CLI
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y \
      git \
      wget \
      curl \
      nano \
      python3-pip \
      python3-venv \
      pipx \
      xz-utils \
      zstd \
      unzip \
      tmux \
      iproute2 \
      python3-debugpy \
      build-essential \
      ripgrep \
      fd-find \
      gpg \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Install Neovim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && \
    rm -rf /opt/nvim && \
    tar -C /opt -xzf nvim-linux-x86_64.tar.gz && \
    mv /opt/nvim-linux-x86_64 /opt/nvim && \
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim && \
    rm nvim-linux-x86_64.tar.gz

# 3. Python Tools
RUN pipx install jedi-language-server

# 4. Clone Config & Setup Tmux
RUN git clone https://github.com/3cnf-f/tmp_nvim.git /root/.config/ && \
    # === THE FIX ===
    # Delete the lockfile so Lazy resolves the latest (working) versions of plugins
    # instead of the old broken ones from the repo.
    # ===============
    cat /root/.config/addto_bashrc >> /root/.bashrc && \
    cat /root/.config/addto_bashaliases >> /root/.bash_aliases && \
    cat /root/.config/.tmux.conf >> /root/.tmux.conf && \
    mkdir -p /root/.tmux/plugins && \
    git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm && \
    mkdir -p /root/docs/ && \
    cp /root/.config/docs/* /root/docs/ && \
    mkdir -p /root/.ssh && \
    touch /root/.ssh/config && \
    cat /root/.config/addto_ssh_config >> /root/.ssh/config


# 5. Install FZF
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf && \
    /root/.fzf/install --all

# 6. Entrypoint (Runtime Config for SSH, Git, and GH)
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'KEY_FILE=/root/.ssh/git_ed25519' >> /usr/local/bin/entrypoint.sh && \
    # --- SSH Key Generation ---
    echo 'if [ ! -f "$KEY_FILE" ]; then' >> /usr/local/bin/entrypoint.sh && \
    echo '  echo "🔑 Generating new SSH key..."' >> /usr/local/bin/entrypoint.sh && \
    echo '  ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -q' >> /usr/local/bin/entrypoint.sh && \
    echo 'fi' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo ""' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo "====== [ SSH PUBLIC KEY ] ======"' >> /usr/local/bin/entrypoint.sh && \
    echo 'cat "${KEY_FILE}.pub"' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo "================================"' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo ""' >> /usr/local/bin/entrypoint.sh && \
    # --- Dynamic Git Config ---
    echo 'echo "⚙️  Configuring Git User: 3cnf-f <$TMP_GITUSER>"' >> /usr/local/bin/entrypoint.sh && \
    echo 'git config --global user.name "3cnf-f"' >> /usr/local/bin/entrypoint.sh && \
    echo 'git config --global user.email "$TMP_GITUSER"' >> /usr/local/bin/entrypoint.sh && \
    # --- GH Auth Logic ---
    echo 'if [ ! -z "$GH_TOKEN" ]; then' >> /usr/local/bin/entrypoint.sh && \
    echo '  echo "🚀 Authenticating GitHub CLI..."' >> /usr/local/bin/entrypoint.sh && \
    echo '  echo "$GH_TOKEN" | gh auth login --with-token' >> /usr/local/bin/entrypoint.sh && \
    echo '  gh auth setup-git' >> /usr/local/bin/entrypoint.sh && \
    echo '  echo "✅ GitHub CLI Authenticated!"' >> /usr/local/bin/entrypoint.sh && \
    echo 'else' >> /usr/local/bin/entrypoint.sh && \
    echo '  echo "ℹ️  No GH_TOKEN provided. Run `gh auth login` manually if needed."' >> /usr/local/bin/entrypoint.sh && \
    echo 'fi' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo ""' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# 7. Pre-install Plugins (The "Bootstrap" Fix)
# This runs Neovim once during the build to download/compile plugins.
# We explicitly ignore errors (|| true) because Treesitter might complain about 
# missing parsers on the first run, but it will download the plugin code correctly.
RUN nvim --headless "+Lazy! sync" +qa || true


WORKDIR /root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
