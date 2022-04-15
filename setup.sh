#!/bin/sh -xe

# set install directory
SRC_REL=`dirname $0`
SRC=`realpath ${SRC_REL}`
INST=${SRC}/sysroot

# install wasi-libc headers
mkdir ${INST}
cd ${SRC}/wasi-libc
make include_dirs
cp -av sysroot/* ${INST}

# compile and install clang, compiler runtime, and libc++
cd ${SRC}/llvm-project
cmake -S llvm -B build -G Ninja -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld" -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi" -DLLVM_RUNTIME_TARGETS="wasm32-wasi" -DLLVM_TARGETS_TO_BUILD=WebAssembly -DLLVM_DEFAULT_TARGET_TRIPLE=wasm32-wasi -DCMAKE_INSTALL_PREFIX=${INST} -DDEFAULT_SYSROOT=${INST} -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER_TARGET=wasm32-wasi -DCMAKE_CROSSCOMPILING=True -DLLVM_TARGET_ARCH=wasm32-wasi -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_THREADS:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_EXCEPTIONS:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_FILESYSTEM:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_EXPERIMENTAL_LIBRARY:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXXABI_ENABLE_EXCEPTIONS:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXXABI_SILENT_TERMINATE:BOOL=ON -DRUNTIMES_wasm32-wasi_LIBCXXABI_ENABLE_THREADS:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_CXX_ABI=libcxxabi -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_SHARED:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXXABI_ENABLE_SHARED:BOOL=OFF -DCOMPILER_RT_BAREMETAL_BUILD=On -DCOMPILER_RT_DEFAULT_TARGET_ONLY=On -DCOMPILER_RT_OS_DIR=wasi -DRUNTIMES_wasm32-wasi_CMAKE_SIZEOF_VOID_P=4 -DRUNTIMES_wasm32-wasi_CMAKE_CXX_FLAGS="-D_LIBCPP_NO_EXCEPTIONS -D_LIBCXXABI_NO_EXCEPTIONS" -DRUNTIMES_wasm32-wasi_LIBCXX_ABI_VERSION=2
ninja -C build runtimes
ninja -C build install install-runtimes

# compile and install wasi-libc
cd ${SRC}/wasi-libc
make -j256 CC=${INST}/bin/clang
cp -av sysroot/* ${INST}

# link "baremetal" compiler runtime to platform-specific compiler runtime
# (clang's "runtimes" build system can only make a "baremetal" compiler-runtime, but clang itself looks for the platform-specific build)
mkdir -p ${INST}/lib/clang/15.0.0/lib/wasi
ln -s ${INST}/lib/clang/15.0.0/lib/wasm32-wasi/libclang_rt.builtins.a ${INST}/lib/clang/15.0.0/lib/wasi/libclang_rt.builtins-wasm32.a
