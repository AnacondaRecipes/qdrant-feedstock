#!/bin/bash

set -ex

cd "${SRC_DIR}"

# Set PROTOC so prost-build can find protoc
export PROTOC=$(command -v protoc)
echo "PROTOC: $PROTOC"

# Conda CFLAGS append -march=x86-64-v2 (last -march wins), which lacks AVX2 and
# breaks lib/quantization (cc-rs uses -march=haswell). Force x86-64-v3 so AVX2
# is available and the baseline is explicit for later repo searches.
export CFLAGS=$(echo "$CFLAGS" | sed -E 's/-march=[^ ]+/-march=x86-64-v3/g')
export CXXFLAGS=$(echo "$CXXFLAGS" | sed -E 's/-march=[^ ]+/-march=x86-64-v3/g')


if [[ "${target_platform}" == linux-* ]]; then
    # Fetch all Cargo dependencies into CARGO_HOME registry before build.
    # We do this explicitly so we can patch vendored crates before compilation.
    cargo fetch
    echo "CARGO_HOME: ${CARGO_HOME}"

    # Find autotools crate dir in cargo registry
    AUTOTOOLS_DIR=$(find "${CARGO_HOME}" \
        -type d -name "autotools-0.2.7" 2>/dev/null | head -1)

    echo "Found: ${AUTOTOOLS_DIR}"

    # autotools-0.2.7 crate has a bug where it passes the full compiler path
    # (e.g. /build_env/bin/aarch64-conda-linux-gnu-gcc) to --host flag instead
    # of just the triplet (aarch64-conda-linux-gnu). This causes configure to
    # fail with "machine not recognized" on conda aarch64 cross-compilation.
    # Fix: patch lib.rs to extract basename from cc_path before strip_suffix.
    # See: https://github.com/lu-zero/autotools-rs (bug not fixed upstream)
    patch -f -p1 -d "${AUTOTOOLS_DIR}" \
        --no-backup-if-mismatch \
        < "${RECIPE_DIR}/patches/correct_host_parse.patch"

    grep "cc_basename" "${AUTOTOOLS_DIR}/src/lib.rs" || {
        echo "ERROR: patch not applied"
        exit 1
    }
    echo "Patch applied OK"
fi

cargo build --release --bin qdrant

mkdir -p "${PREFIX}/bin"
cp target/release/qdrant "${PREFIX}/bin/qdrant"
chmod +x "${PREFIX}/bin/qdrant"
