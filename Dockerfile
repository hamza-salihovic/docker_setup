# Start from Ubuntu 22.04 (Jammy Jellyfish) for x86_64
FROM --platform=linux/amd64 ubuntu:22.04

# Add LLVM and GCC repositories for x86_64
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install \
    wget \
    gnupg \
    software-properties-common \
    && wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository "deb [arch=amd64] http://apt.llvm.org/jammy/ llvm-toolchain-jammy main" \
    && add-apt-repository ppa:ubuntu-toolchain-r/test

# Update the system and install utils
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo \
    cmake \
    meson \
    valgrind \
    build-essential \
    binutils \
    clang \
    clang-14 \
    clang-12 \
    lldb-12 \
    gdb \
    gcc-11 \
    g++-11 \
    gcc-10 \
    g++-10 \
    zsh \
    git \
    wget \
    curl \
    python3 python3-venv python3-pip \
    libreadline-dev \
    libreadline8 \
    xorg libxext-dev zlib1g-dev libbsd-dev \
    libcmocka-dev \
    pkg-config \
    cppcheck \
    clangd \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Set up compiler aliases
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 100 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/clang-12 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-12 100

# Valgrind 3.18.1 (x86_64 compatible)
RUN wget https://sourceware.org/pub/valgrind/valgrind-3.18.1.tar.bz2 \
    && tar -xjf valgrind-3.18.1.tar.bz2 \
    && cd valgrind-3.18.1 \
    && ./configure --host=x86_64-linux-gnu \
    && make \
    && make install \
    && sudo ldconfig \
    && cd .. \
    && rm -rf valgrind-3.18.1*

# Make 4.3 (x86_64 compatible)
RUN wget http://ftp.gnu.org/gnu/make/make-4.3.tar.gz \
    && tar -xvzf make-4.3.tar.gz \
    && cd make-4.3 \
    && ./configure --host=x86_64-linux-gnu \
    && make \
    && sudo make install \
    && cd .. \
    && rm -rf make-4.3*

# Readline 8.1 (x86_64 compatible)
RUN wget https://ftp.gnu.org/gnu/readline/readline-8.1.tar.gz \
    && tar -xzvf readline-8.1.tar.gz \
    && cd readline-8.1 \
    && ./configure --enable-shared --host=x86_64-linux-gnu \
    && make \
    && sudo make install \
    && sudo ldconfig \
    && cd .. \
    && rm -rf readline-8.1*

# Create a virtual environment and activate it
RUN python3 -m venv /opt/venv
RUN chown -R $USER:$USER /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and setuptools and install norminette
RUN python3 -m pip install --upgrade pip setuptools
RUN python3 -m pip install norminette

# Install MLX library
RUN cd $HOME \
    && git clone https://github.com/42Paris/minilibx-linux.git \
    && cd minilibx-linux \
    && make \
    && sudo cp mlx.h /usr/local/include \
    && sudo cp libmlx.a /usr/local/lib

# Install francinette
RUN bash -c "$(curl -fsSL https://raw.github.com/xicodomingues/francinette/master/bin/install.sh)"

# Add .specstory/ to .gitignore if not already present
RUN grep -q ".specstory/" .gitignore || echo ".specstory/" >> .gitignore

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
RUN echo "source $HOME/.oh-my-zsh/oh-my-zsh.sh" >> $HOME/.zshrc

# Install c_formatter_42 and fix the binary compatibility issue
RUN python3 -m pip install c_formatter_42 && \
    apt-get update && apt-get install -y clang-format file && \
    cp /usr/bin/clang-format /opt/venv/lib/python3.10/site-packages/c_formatter_42/data/clang-format-linux && \
    chmod +x /opt/venv/lib/python3.10/site-packages/c_formatter_42/data/clang-format-linux && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Optional: Clean up the cloned repository
RUN rm -rf /tmp/c_formatter_42

# Set the working directory in the container
WORKDIR /app

# Add .specstory/ to .gitignore if not already present, then start zsh
CMD ["/bin/bash", "-c", "grep -q '.specstory/' .gitignore || echo '.specstory/' >> .gitignore; exec /bin/zsh"]
