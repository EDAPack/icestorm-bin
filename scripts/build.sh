#!/bin/sh -x

root=$(pwd)

#********************************************************************
#* Install required packages
#********************************************************************
if test $(uname -s) = "Linux"; then
    # yum works on manylinux2014 (CentOS 7) and is a compat shim on newer images
    # cmake and libusb1-devel are needed to build libftdi from source (for iceprog)
    yum install -y make gcc gcc-c++ git python3 patchelf cmake libusb1-devel
    if test -z $image; then
        image=linux
    fi
    rls_plat=${image}
fi

#********************************************************************
#* Validate environment variables
#********************************************************************
if test -z "${icestorm_version}"; then
    if test -z "${BUILD_NUM}"; then
        icestorm_version="1.1"
    else
        icestorm_version="1.1.${BUILD_NUM}"
    fi
fi

rls_version="${icestorm_version}"

echo "icestorm_version: ${icestorm_version}"
echo "rls_version:      ${rls_version}"
echo "rls_plat:         ${rls_plat}"

#********************************************************************
#* Build libftdi from source
#* (not available in manylinux repos; needed for iceprog)
#********************************************************************
LIBFTDI_VERSION=1.5
staging_dir="${root}/staging"
mkdir -p "${staging_dir}"

if test ! -d "${root}/libftdi1-${LIBFTDI_VERSION}"; then
    curl -fL "https://www.intra2net.com/en/developer/libftdi/download/libftdi1-${LIBFTDI_VERSION}.tar.bz2" \
        | tar -xj -C "${root}"
    if test $? -ne 0; then exit 1; fi
fi

cmake -S "${root}/libftdi1-${LIBFTDI_VERSION}" -B "${root}/libftdi1-build" \
    -DCMAKE_INSTALL_PREFIX="${staging_dir}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DFTDIPP=OFF \
    -DPYTHON_BINDINGS=OFF \
    -DDOCUMENTATION=OFF \
    -DEXAMPLES=OFF \
    -DTESTS=OFF \
    -DFTDI_EEPROM=OFF
if test $? -ne 0; then exit 1; fi

cmake --build "${root}/libftdi1-build" --parallel
if test $? -ne 0; then exit 1; fi

cmake --install "${root}/libftdi1-build"
if test $? -ne 0; then exit 1; fi

#********************************************************************
#* Clone icestorm
#********************************************************************
if test ! -d icestorm; then
    git clone https://github.com/YosysHQ/icestorm icestorm
    if test $? -ne 0; then exit 1; fi
fi
git config --global --add safe.directory ${root}/icestorm

#********************************************************************
#* Build icestorm
#********************************************************************
release_dir="${root}/release/icestorm"
rm -rf "${release_dir}"
mkdir -p "${release_dir}"

cd ${root}/icestorm
# PKG_CONFIG_PATH lets the iceprog Makefile find our staged libftdi1
export PKG_CONFIG_PATH="${staging_dir}/lib/pkgconfig:${staging_dir}/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
make -j$(nproc) ICEPROG=1 PREFIX="${release_dir}" CXX=g++ CC=gcc
if test $? -ne 0; then exit 1; fi

make install ICEPROG=1 PREFIX="${release_dir}"
if test $? -ne 0; then exit 1; fi

cd ${root}

# Bundle libftdi shared library into the release so iceprog can find it at runtime
mkdir -p "${release_dir}/lib"
# lib64 on CentOS/RHEL, lib on others — copy whichever exists
for libdir in "${staging_dir}/lib64" "${staging_dir}/lib"; do
    if ls "${libdir}"/libftdi1.so* 2>/dev/null | grep -q .; then
        cp -P "${libdir}"/libftdi1.so* "${release_dir}/lib/"
        break
    fi
done

# Set ORIGIN-relative rpath so iceprog finds the bundled libftdi1
patchelf --set-rpath '$ORIGIN/../lib' "${release_dir}/bin/iceprog"
if test $? -ne 0; then exit 1; fi

# Copy export.envrc for ivpm PATH integration
cp ${root}/scripts/export.envrc "${release_dir}/"

#********************************************************************
#* Stage Agent Skills
#********************************************************************
# Skills are authored under skills/<name>/ and listed in
# scripts/skill-manifest.yaml.  update/stage-skills.py validates each
# skill's frontmatter and binary references and emits skills/index.json.
manifest="${root}/scripts/skill-manifest.yaml"
if test -f "${manifest}"; then
    echo "=== Staging Agent Skills ==="
    python3 "${root}/../update/stage-skills.py" \
        --manifest "${manifest}" \
        --source-root "${root}" \
        --release-root "${release_dir}" \
        --dest "${release_dir}/skills"
    if test $? -ne 0; then
        echo "ERROR: skill staging failed" >&2
        exit 1
    fi
fi

#********************************************************************
#* Create release tarball
#********************************************************************
cd ${root}/release
tar czf icestorm-${rls_plat}-${rls_version}.tar.gz icestorm
if test $? -ne 0; then exit 1; fi

echo "Build complete: release/icestorm-${rls_plat}-${rls_version}.tar.gz"
