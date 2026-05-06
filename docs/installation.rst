Installation
============

From a GitHub Release tarball
-------------------------------

Download the latest tarball from the
`GitHub Releases page <https://github.com/EDAPack/icestorm-bin/releases>`_.
Extract it to a convenient location and add the ``bin/`` directory to your
``PATH``::

    tar xzf icestorm-manylinux_2_34_x86_64-<version>.tar.gz
    export PATH="$(pwd)/icestorm/bin:${PATH}"

Verify the tools are available::

    $ icepack --help
    $ icetime --help

With IVPM
---------

`IVPM <https://github.com/fvutils/ivpm>`_ users can declare a dependency
directly in their project's ``ivpm.yaml``::

    package:
      dep-sets:
        - name: default-dev
          deps:
            - name: icestorm-bin
              src: gh-rls
              url: https://github.com/EDAPack/icestorm-bin

Then run::

    ivpm update

IVPM will prepend the bundled ``bin/`` directory to ``PATH`` automatically
(via the ``env`` section in ``ivpm.yaml``).

System requirements
-------------------

* Linux x86-64 with **glibc ≥ 2.34** (manylinux_2_34).
* No additional runtime libraries required — all C/C++ dependencies are
  statically linked or bundled.
* ``python3`` on ``PATH`` is needed by the ``icebox`` Python utilities.
