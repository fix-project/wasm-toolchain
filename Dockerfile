FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
  git \
  cmake \
  ninja-build \
  build-essential \
  pkg-config \
  zlib1g-dev \
  clang \
  libclang-dev \
  libcrypto++-dev \
  lld \
  sudo

ENV HOME=/home

RUN cd $HOME && \
    git clone https://github.com/fixpointOS/wasm-toolchain.git && \
    cd wasm-toolchain && \
    git submodule update --init && \
    ./build.sh && \
    rm -rf llvm-project && \
    rm -rf wasi-libc
