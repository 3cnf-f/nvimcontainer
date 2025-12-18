FROM ubuntu:latest

ENV LANG=C.UTF-8 \
    TERM=xterm-256color \
    TZ=Europe/Stockholm \
    DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.local/bin:$PATH"

# 1. Base Dependencies & Python
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

# 2. Install Neovim (Latest Stable)
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && \
    rm -rf /opt/nvim && \
    tar -C /opt -xzf nvim-linux-x86_64.tar.gz && \
    mv /opt/nvim-linux-x86_64 /opt/nvim && \
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim && \
    rm nvim-linux-x86_64.tar.gz

# 3. Python Tools (Jedi via pipx)
RUN pipx install jedi-language-server

# 4. Clone Config & Setup Tmux
# Note: This clones your GitHub repo. If you want to test LOCAL changes, 
# you should mount your local folder when running the container (see instructions below).
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

# 6. SSH Key Generation & Display
# This will generate the key and print the .pub content to the build log
RUN ssh-keygen -t ed25519 -f /root/.ssh/git_ed25519 -N "" && \
    echo "\n\n====== [ SSH PUBLIC KEY ] ======" && \
    cat /root/.ssh/git_ed25519.pub && \
    echo "================================\n\n"

# 7. Git Configuration
# We use a build argument for the email. Default is set if not provided.
ARG TMP_GITUSER=temp_dev@example.com
RUN git config --global user.name "3cnf-f" && \
    git config --global user.email "$TMP_GITUSER" && \
    echo "echo 'Git Configured: 3cnf-f <$TMP_GITUSER>'" >> /root/.bashrc

# 8. Entrypoint
WORKDIR /root
CMD ["/bin/bash"]
