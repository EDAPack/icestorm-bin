Overview
========

**icestorm-bin** packages `Project IceStorm
<https://prjicestorm.readthedocs.io/>`_ into a single manylinux-compatible
release artefact for Linux.

What is Project IceStorm?
--------------------------

Project IceStorm documents the bitstream format of Lattice iCE40 FPGAs and
provides tools for working with those bitstreams. It is a foundational
component of the open-source iCE40 FPGA toolchain alongside
`nextpnr <https://github.com/YosysHQ/nextpnr>`_ (place-and-route) and
`Yosys <https://yosyshq.net/yosys/>`_ (synthesis).

Why icestorm-bin?
-----------------

Upstream Project IceStorm is source-only. icestorm-bin provides ready-to-use
binaries that:

* Run on any Linux system with glibc ≥ 2.34 (AlmaLinux 9+, Ubuntu 22.04+,
  Debian 12+, Fedora 37+, …).
* Require no build dependencies — just extract and use.
* Integrate with `IVPM <https://github.com/fvutils/ivpm>`_ so downstream
  projects can declare a binary dependency and have ``PATH`` set automatically.

Bundled components
------------------

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Component
     - Description
   * - ``icepack``
     - Pack/unpack iCE40 bitstream files
   * - ``icebox``
     - Python library and utilities for introspecting iCE40 netlists
   * - ``icetime``
     - Static timing analysis for iCE40 designs
   * - ``icemulti``
     - Combine multiple bitstreams for iCE40 multi-boot
   * - ``icepll``
     - PLL configuration calculator for iCE40
   * - ``icebram``
     - Replace BRAM initialisation data in bitstreams

Release naming
--------------

Releases are versioned as ``1.1.<ci-run-id>`` and named::

    icestorm-manylinux_2_34_x86_64-1.1.<run-id>.tar.gz
