#!/bin/sh -x

root=$(pwd)

#********************************************************************
#* Install required packages
#********************************************************************
if test $(uname -s) = "Linux"; then
    dnf update -y
    dnf install -y wget make gcc gcc-c++ git python3 patchelf \
        libftdi-devel libusb-devel
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
# Build without iceprog (requires hardware USB access, not useful in binary dist)
make -j$(nproc) ICEPROG=0 PREFIX="${release_dir}" CXX=g++ CC=gcc
if test $? -ne 0; then exit 1; fi

make install ICEPROG=0 PREFIX="${release_dir}"
if test $? -ne 0; then exit 1; fi

# Copy export.envrc for ivpm PATH integration
cp ${root}/scripts/export.envrc "${release_dir}/"

#********************************************************************
#* Create release tarball
#********************************************************************
cd ${root}/release
tar czf icestorm-${rls_plat}-${rls_version}.tar.gz icestorm
if test $? -ne 0; then exit 1; fi

echo "Build complete: release/icestorm-${rls_plat}-${rls_version}.tar.gz"
