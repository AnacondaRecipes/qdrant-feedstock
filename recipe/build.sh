#!/bin/bash

set -e

cd "${SRC_DIR}"

# Set PROTOC so prost-build can find protoc
export PROTOC=$(command -v protoc)

cargo build --release --bin qdrant

mkdir -p "${PREFIX}/bin"
cp target/release/qdrant "${PREFIX}/bin/qdrant"
chmod +x "${PREFIX}/bin/qdrant"
