FROM ubuntu:latest

ENV LANG=C.UTF-8 \
    TERM=xterm-256color \
    TZ=Europe/Stockholm \
    DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.local/bin:$PATH"

# 1. Base Dependencies
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

# 6. Create Entrypoint Script (Run-time Key Generation)
# We write this script to /usr/local/bin and make it executable.
# It checks for a key, generates it if missing, prints it, then runs the command.
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'KEY_FILE=/root/.ssh/git_ed25519' >> /usr/local/bin/entrypoint.sh && \
    echo 'if [ ! -f "$KEY_FILE" ]; then' >> /usr/local/bin/entrypoint.sh && \
    echo '  echo "🔑 Generating new SSH key..."' >> /usr/local/bin/entrypoint.sh && \
    echo '  ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -q' >> /usr/local/bin/entrypoint.sh && \
    echo 'fi' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo ""' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo "====== [ SSH PUBLIC KEY ] ======"' >> /usr/local/bin/entrypoint.sh && \
    echo 'cat "${KEY_FILE}.pub"' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo "================================"' >> /usr/local/bin/entrypoint.sh && \
    echo 'echo ""' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# 7. Git Configuration
ARG TMP_GITUSER=temp_dev@example.com
RUN git config --global user.name "3cnf-f" && \
    git config --global user.email "$TMP_GITUSER" && \
    echo "echo 'Git Configured: 3cnf-f <$TMP_GITUSER>'" >> /root/.bashrc

# 8. Set Entrypoint
WORKDIR /root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
