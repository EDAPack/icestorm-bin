Building from Source
====================

icestorm-bin is built inside a `manylinux_2_34
<https://github.com/pypa/manylinux>`_ Docker container so the resulting
binaries work on any Linux system with glibc ≥ 2.34.

Prerequisites
-------------

* Docker (any recent version)
* ``git`` with the repository cloned

Build script
------------

The entire build is driven by ``scripts/build.sh``.  The ``build-local.sh``
wrapper invokes it inside the correct Docker container::

    ./scripts/build-local.sh

You can also specify a different manylinux image::

    ./scripts/build-local.sh manylinux_2_28_x86_64

Or run Docker directly::

    docker run --rm \
        --volume "$(pwd):/io" \
        --env image=manylinux_2_34_x86_64 \
        --workdir /io \
        quay.io/pypa/manylinux_2_34_x86_64 \
        /io/scripts/build.sh

The script performs the following steps:

1. **System dependencies** — installs build tools (``gcc``, ``gcc-c++``,
   ``make``, ``git``, ``python3``) via ``dnf``.

2. **Clone icestorm** — clones
   `YosysHQ/icestorm <https://github.com/YosysHQ/icestorm>`_ from the
   ``main`` branch (if not already present).

3. **Build** — runs ``make -j$(nproc) ICEPROG=0 PREFIX=<release_dir>``
   (``iceprog`` is excluded as it requires USB hardware access).

4. **Install** — runs ``make install`` into the release staging directory.

5. **Tarball** — packs the release directory into
   ``release/icestorm-<image>-<version>.tar.gz``.

Environment variables
---------------------

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Variable
     - Description
   * - ``image``
     - manylinux image name used as the platform tag in the release filename
       (default: ``linux``).
   * - ``icestorm_version``
     - Override the full release version string.  Defaults to
       ``1.1.<BUILD_NUM>`` when ``BUILD_NUM`` is set, or ``1.1`` otherwise.
   * - ``BUILD_NUM``
     - GitHub Actions run ID appended to the version for traceability.

CI / GitHub Actions
-------------------

The workflow in ``.github/workflows/ci.yml`` runs automatically on every push
and on a weekly schedule (Sunday 12:00 UTC).

Steps:

1. **version-check** — constructs the release version string as
   ``1.1.<run-id>``.
2. **build-linux-x86_64** — launches the Docker-based build inside
   ``manylinux_2_34_x86_64``.
3. **publish** — creates a GitHub Release and attaches the tarball.

Documentation is built separately and published to GitHub Pages whenever
``main`` is updated (see ``.github/workflows/docs.yml``).

Release layout
--------------

The unpacked release directory contains::

    bin/
      icepack
      icetime
      icemulti
      icepll
      icebram
      icebox_chipdb
      icebox_hlc
      icebox_stat
      icebox_vlog
    lib/
      python3/
        site-packages/
          icebox/
    share/
      icebox/
        chipdb-*.txt
    export.envrc
