# icestorm-bin

**icestorm-bin** is a portable, pre-built distribution of
[Project IceStorm](https://prjicestorm.readthedocs.io/) for Linux
(manylinux 2.34 / glibc 2.34+).

Project IceStorm documents the bitstream format of Lattice iCE40 FPGAs and
provides tools for packing, unpacking, and analysing bitstreams. It is a
foundational component of the open-source iCE40 FPGA toolchain alongside
[nextpnr](https://github.com/YosysHQ/nextpnr) and
[Yosys](https://yosyshq.net/yosys/).

## Quick start

Download the latest release tarball, extract, and add to PATH:

```sh
tar xzf icestorm-manylinux_2_34_x86_64-<version>.tar.gz
export PATH="$(pwd)/icestorm/bin:${PATH}"
icepack --help
```

## Building locally

```sh
./scripts/build-local.sh
```

Requires Docker. The build runs inside `quay.io/pypa/manylinux_2_34_x86_64`.

## Documentation

Full documentation is published at
[https://EDAPack.github.io/icestorm-bin](https://EDAPack.github.io/icestorm-bin).

## License

This packaging infrastructure is MIT licensed.
Project IceStorm itself is licensed under the ISC license.
