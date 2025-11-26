#!/bin/bash

set -e

cd "${SRC_DIR}"

# Set PROTOC so prost-build can find protoc
export PROTOC=$(command -v protoc)
export LIBCLANG_PATH="${PREFIX}/lib"

# Remove -march=nocona from CFLAGS/CXXFLAGS to avoid conflict with AVX2 code
# The build.rs script sets -march=haswell for AVX2 support, but conda-build
# sets -march=nocona which doesn't support AVX2 instructions
export CFLAGS=$(echo "$CFLAGS" | sed 's/-march=nocona//g')
export CXXFLAGS=$(echo "$CXXFLAGS" | sed 's/-march=nocona//g')

cargo build --release --bin qdrant

mkdir -p "${PREFIX}/bin"
cp target/release/qdrant "${PREFIX}/bin/qdrant"
chmod +x "${PREFIX}/bin/qdrant"
