#!/usr/bin/env bash
# icestorm-bin build driver.
#
# Builds Project IceStorm (icepack/iceprog/icetime/...) from the exact commit
# resolved by edapack-common's resolve-inputs.py, bundling libftdi (built from a
# pinned source tarball) so iceprog is self-contained, and emits a release
# manifest.
#
# Runs in CI (reusable workflow) and locally (local-build.sh). All transient
# state — including the libftdi download/build/staging that previously left
# root-owned dirs in the workspace — now goes to WORK_DIR. Tarball + manifest
# land in OUT_DIR; the source tree is never written to.
set -euo pipefail

# --- locate edapack-common --------------------------------------------------
if [ -z "${EC_COMMON:-}" ]; then
    _cand="$(cd "$(dirname "$0")/../../edapack-common" 2>/dev/null && pwd || true)"
    [ -n "$_cand" ] && EC_COMMON="$_cand"
fi
if [ -z "${EC_COMMON:-}" ] || [ ! -f "$EC_COMMON/scripts/build-common.sh" ]; then
    echo "ERROR: edapack-common not found. Set EC_COMMON or place edapack-common beside icestorm-bin." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$EC_COMMON/scripts/build-common.sh"

: "${EC_PACKAGE:=icestorm-bin}"
export EC_PACKAGE
ec_init_dirs
ec_prepare_candidate

os="$(uname -s)"
plat="${EC_IMAGE_NAME:-}"
[ "$os" = "Linux" ] && : "${plat:=linux}"
njobs="$(nproc 2>/dev/null || echo 4)"

if [ "${EC_INSTALL_DEPS:-0}" = "1" ] && [ "$os" = "Linux" ]; then
    yum install -y make gcc gcc-c++ git python3 patchelf cmake libusb1-devel || true
fi

# --- libftdi (pinned source tarball, built into WORK_DIR) -------------------
LIBFTDI_VERSION=1.5
staging_dir="$WORK_DIR/staging"
libftdi_src="$WORK_DIR/libftdi1-${LIBFTDI_VERSION}"
libftdi_build="$WORK_DIR/libftdi1-build"
mkdir -p "$staging_dir"
if [ ! -d "$libftdi_src" ]; then
    curl -fL "https://www.intra2net.com/en/developer/libftdi/download/libftdi1-${LIBFTDI_VERSION}.tar.bz2" \
        | tar -xj -C "$WORK_DIR"
fi
cmake -S "$libftdi_src" -B "$libftdi_build" \
    -DCMAKE_INSTALL_PREFIX="$staging_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DFTDIPP=OFF -DPYTHON_BINDINGS=OFF -DDOCUMENTATION=OFF \
    -DEXAMPLES=OFF -DTESTS=OFF -DFTDI_EEPROM=OFF
cmake --build "$libftdi_build" --parallel
cmake --install "$libftdi_build"

# --- icestorm (resolved commit) ---------------------------------------------
ice_src="$(ec_clone_input icestorm "$(ec_core_get repo)" "$(ec_core_get resolved_sha)")"
release_root="$WORK_DIR/release/icestorm"
rm -rf "$release_root"; mkdir -p "$release_root"

export PKG_CONFIG_PATH="${staging_dir}/lib/pkgconfig:${staging_dir}/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
make -C "$ice_src" -j"$njobs" ICEPROG=1 PREFIX="$release_root" CXX=g++ CC=gcc
make -C "$ice_src" install ICEPROG=1 PREFIX="$release_root"

# --- bundle libftdi + rpath iceprog -----------------------------------------
mkdir -p "$release_root/lib"
for libdir in "$staging_dir/lib64" "$staging_dir/lib"; do
    if ls "$libdir"/libftdi1.so* 2>/dev/null | grep -q .; then
        cp -P "$libdir"/libftdi1.so* "$release_root/lib/"
        break
    fi
done
[ -e "$release_root/bin/iceprog" ] && patchelf --set-rpath '$ORIGIN/../lib' "$release_root/bin/iceprog"

# --- shared release tail ----------------------------------------------------
ec_finalize_release "$SRC_DIR" "$release_root" "$CANDIDATE_JSON"
tarball="icestorm-${plat}-${EC_VERSION}.tar.gz"
ec_make_tarball "$release_root" "$tarball"
ec_log "build complete: $tarball"
