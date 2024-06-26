FROM ubuntu:24.04

RUN apt-get -y update && apt-get -y upgrade && apt-get install -y \
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
  gh \
  unzip \
  sudo

ENV HOME=/home

RUN cd $HOME && \
    git clone https://github.com/fix-project/wasm-toolchain.git && \
    cd wasm-toolchain && \
    git submodule update --init --recursive --depth 1 && \
    ./build.sh && \
    rm -rf wasi-libc
