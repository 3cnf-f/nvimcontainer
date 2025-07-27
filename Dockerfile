FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Update, upgrade, and install base dependencies plus Python LSP packages (excluding pylsp-ruff)
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
      #  python3-pip \
      #  python3-venv \
      #  pipx \
      xz-utils \
      zstd \
      unzip \
      tmux \
      #iproute2 \
      build-essential 
      # python3-flask \

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8\
    TZ=UTC

# Install Neovim (latest release, portable binary)
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && \
    rm -rf /opt/nvim && \
    tar -C /opt -xzf nvim-linux-x86_64.tar.gz && \
    mv /opt/nvim-linux-x86_64 /opt/nvim && \
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim && \
    rm nvim-linux-x86_64.tar.gz

# Clone the custom Neovim and tmux config
RUN git clone https://github.com/3cnf-f/tmp_nvim.git /root/.config/ && \
    cat /root/.config/addto_bashrc >>/root/.bashrc && \
    cat /root/.config/addto_bashaliases >>/root/.bash_aliases && \
    cat /root/.config/.tmux.conf >>/root/.tmux.conf &&\
    mkdir -p /root/.tmux/plugins &&\
    git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm &&\
    mkdir -p /root/docs/ &&\
    cp /root/.config/docs /root/docs/ &&\
    mkdir -p /root/.ssh && \
    cat /root/.config/addto_ssh_config >>/root/.ssh/config &&\
    cat /root/.config/add_locale_to_bashrc >> ~/.bashrc &&\
    cat /root/.config/addto_def_locale >> /etc/default/locale &&\
    cat /root/.config/addto_locale_gen >>  /etc/locale.gen&&\
    locale-gen 






# Install fzf (as in the setup)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf && \
     /root/.fzf/install --all

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup SSH server
RUN mkdir /var/run/sshd

# Enable root SSH login with password (change 'root' to a secure password!)
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
