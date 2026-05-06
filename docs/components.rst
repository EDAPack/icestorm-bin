Components
==========

icepack
-------

``icepack`` packs and unpacks iCE40 bitstream files.  It converts between the
binary ``.bin`` format (written to flash) and the text ``.asc`` format used
by ``icetime`` and ``icebox``::

    icepack design.asc design.bin       # pack to binary
    icepack -u design.bin design.asc    # unpack to text

icebox
------

``icebox`` is both a Python library and a collection of command-line utilities
for introspecting iCE40 netlists.  It provides:

* ``icebox_chipdb`` — generate chip database files
* ``icebox_hlc`` — convert bitstream to high-level connectivity description
* ``icebox_stat`` — print bitstream resource utilisation statistics
* ``icebox_vlog`` — convert bitstream to Verilog netlist

As a Python library it exposes the full chip database and bitstream
manipulation API::

    import icebox
    ic = icebox.iceconfig()
    ic.read_file("design.asc")

icetime
-------

``icetime`` performs static timing analysis on an iCE40 ``.asc`` bitstream
and reports the maximum clock frequency for each clock domain::

    icetime -d hx8k design.asc

icemulti
--------

``icemulti`` combines multiple iCE40 bitstreams into a single file for
multi-boot configurations::

    icemulti -v -o multi.bin boot0.bin boot1.bin

icepll
------

``icepll`` is an interactive PLL configuration calculator.  Given a desired
output frequency it computes the PLL divider settings for the target iCE40
device::

    icepll -i 12 -o 48

icebram
-------

``icebram`` replaces the BRAM initialisation data in an existing ``.asc``
bitstream without a full re-synthesis, which is useful for updating firmware
images::

    icebram firmware_old.hex firmware_new.hex < design.asc > updated.asc
