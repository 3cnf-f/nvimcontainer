FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Update, upgrade, and install base dependencies plus Python LSP packages (excluding ruff)
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y \
      locales \
      keyboard-configuration \
      tzdata \
      git \
      wget \
      curl \
      nano \
      openssh-server \
      python3-pip \
      python3-venv \
      pipx \
      xz-utils \
      zstd \
      unzip \
      iproute2 \
      build-essential \
      npm \
      nodejs \
      python3-flask \
      # Python LSP core and plugins (equivalent to python-lsp-server[all] minus ruff)
      python3-pylsp \
      flake8 \
      pylint \
      python3-autopep8 \
      python3-mccabe \
      python3-pycodestyle \
      python3-pydocstyle \
      python3-pyflakes \
      python3-rope \
      python3-whatthepatch \
      python3-yapf \
      python3-mypy \
      python3-pylsp-black \
      python3-pylsp-isort

# Set up Swedish keyboard and timezone (language stays default)
RUN sed -i '/sv_SE.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    echo 'XKBLAYOUT="se"' > /etc/default/keyboard && \
    dpkg-reconfigure -f noninteractive keyboard-configuration && \
    ln -fs /usr/share/zoneinfo/Europe/Stockholm /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install Neovim (latest release, portable binary)
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && \
    rm -rf /opt/nvim && \
    tar -C /opt -xzf nvim-linux-x86_64.tar.gz && \
    mv /opt/nvim-linux-x86_64 /opt/nvim && \
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim && \
    rm nvim-linux-x86_64.tar.gz

# Clone the custom Neovim config
RUN git clone https://github.com/3cnf-f/tmp_nvim.git /root/.config/ && \
    cat /root/.config/addto_bashrc >>/root/.bashrc && \
    cat /root/.config/addto_bashaliases >>/root/.bash_aliases && \
    mkdir -p /root/.ssh && \
    cat /root/.config/addto_ssh_config >>/root/.ssh/config

# Install fzf (as in the setup)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf && \
    /root/.fzf/install --all

# Install Python LSP (pyright via npm only now)
RUN npm install -g pyright

# Install JavaScript/TypeScript LSP (typescript-language-server)
RUN npm install -g typescript typescript-language-server

# Install HTML LSP
RUN npm install -g vscode-langservers-extracted

# Install windsurf/cursor LSP (assuming you mean "cursor" from windsurf/cursor)
RUN npm install -g @windsurf/cursor

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup SSH server
RUN mkdir /var/run/sshd

# Enable root SSH login with password (change 'root' to a secure password!)
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
