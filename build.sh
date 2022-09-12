#!/bin/sh -xe

# set install directory
SRC_REL=`dirname $0`
SRC=`realpath ${SRC_REL}`
INST=${SRC}/sysroot

# compile wabt
cd ${SRC}/wabt
cmake -S . -B build/ -DBUILD_TESTS=OFF
cmake --build build/ --parallel $(nproc)

# compile wasm-tools
cd ${SRC}/wasm-tools
cmake -S . -B build/ -DBUILD_TESTS=OFF
cmake --build build/ --parallel $(nproc)

# install wasi-libc headers
mkdir ${INST}
cd ${SRC}/wasi-libc
make include_dirs
cp -av sysroot/* ${INST}

#install wasix headers
mkdir ${INST}/wasix
mkdir ${INST}/wasix/include
cd ${SRC}/wasix
cp -av include/* ${INST}/wasix/include

# compile and install clang, compiler runtime, and libc++
cd ${SRC}/llvm-project
cmake -S llvm -B build -G Ninja -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld" -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi" -DLLVM_RUNTIME_TARGETS="wasm32-wasi" -DLLVM_TARGETS_TO_BUILD=WebAssembly -DLLVM_DEFAULT_TARGET_TRIPLE=wasm32-wasi -DCMAKE_INSTALL_PREFIX=${INST} -DDEFAULT_SYSROOT=${INST} -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER_TARGET=wasm32-wasi -DCMAKE_CROSSCOMPILING=True -DLLVM_TARGET_ARCH=wasm32-wasi -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_THREADS:BOOL=ON -DRUNTIMES_wasm32-wasi_LIBCXX_HAS_PTHREAD_API:BOOL=ON -DRUNTIMES_wasm32-wasi_LIBCXX_HAS_EXTERNAL_THREAD_API:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_BUILD_EXTERNAL_THREAD_LIBRARY:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_EXCEPTIONS:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_FILESYSTEM:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_EXPERIMENTAL_LIBRARY:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXXABI_ENABLE_EXCEPTIONS:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXXABI_SILENT_TERMINATE:BOOL=ON -DRUNTIMES_wasm32-wasi_LIBCXXABI_ENABLE_THREADS:BOOL=ON -DRUNTIMES_wasm32-wasi_LIBCXXABI_HAS_PTHREAD_API:BOOL=ON -DRUNTIMES_wasm32-wasi_LIBCXXABI_HAS_EXTERNAL_THREAD_API:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXXABI_BUILD_EXTERNAL_THREAD_LIBRARY:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXX_CXX_ABI=libcxxabi -DRUNTIMES_wasm32-wasi_LIBCXX_ENABLE_SHARED:BOOL=OFF -DRUNTIMES_wasm32-wasi_LIBCXXABI_ENABLE_SHARED:BOOL=OFF -DCOMPILER_RT_BAREMETAL_BUILD=On -DCOMPILER_RT_DEFAULT_TARGET_ONLY=On -DCOMPILER_RT_OS_DIR=wasi -DRUNTIMES_wasm32-wasi_CMAKE_SIZEOF_VOID_P=4 -DRUNTIMES_wasm32-wasi_CMAKE_CXX_FLAGS="-I${HOME}/wasm-toolchain/sysroot/wasix/include -D_LIBCPP_NO_EXCEPTIONS -D_LIBCXXABI_NO_EXCEPTIONS" -DRUNTIMES_wasm32-wasi_LIBCXX_ABI_VERSION=2
ninja -C build runtimes
ninja -C build install install-runtimes
ninja -C build clang-tblgen
cp build/bin/clang-tblgen ${INST}/bin/clang-tblgen

# compile and install wasi-libc
cd ${SRC}/wasi-libc
make -j256 CC=${INST}/bin/clang AR=${INST}/bin/llvm-ar NM=${INST}/bin/llvm-nm
cp -av sysroot/* ${INST}

# compile and install wasix
cd ${SRC}/wasix
export WASI_SDK_PATH="${HOME}/wasm-toolchain/sysroot"
export WASI_SYSROOT="${HOME}/wasm-toolchain/sysroot"
export DESTDIR="${HOME}/wasm-toolchain/sysroot/wasix"
make install

# link "baremetal" compiler runtime to platform-specific compiler runtime
# (clang's "runtimes" build system can only make a "baremetal" compiler-runtime, but clang itself looks for the platform-specific build)
mkdir -p ${INST}/lib/clang/16.0.0/lib/wasi
ln -s ${INST}/lib/clang/16.0.0/lib/wasm32-wasi/libclang_rt.builtins.a ${INST}/lib/clang/16.0.0/lib/wasi/libclang_rt.builtins-wasm32.a
