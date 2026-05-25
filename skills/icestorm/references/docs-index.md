# icestorm documentation index

## Primary
- **Project site** — http://bygone.clairexen.net/icestorm/
- **Source repo** — https://github.com/YosysHQ/icestorm
- **README (top of repo)** — quick architecture and tool list.
- **Per-tool man pages** — built from source: `man icepack`, `man iceprog`, etc.

## Topic-specific
- **iCE40 bitstream reverse-engineering write-up** —
  http://www.clifford.at/papers/2015/icestorm/
  (explains the file formats and silicon architecture; useful when
  reading `icebox_vlog` output.)
- **iceprog protocol / SPI flash layout** —
  https://github.com/YosysHQ/icestorm/blob/master/iceprog/iceprog.c
  (the source is the spec — flag handling is well-commented.)
- **Lattice iCE40 datasheets** — vendor PDFs (search Lattice site for
  the exact part: HX1K, HX8K, UP5K, U4K, etc.).

## Worked examples in the wild
- **picorv32 iCE40 examples** —
  https://github.com/YosysHQ/picorv32/tree/main/picosoc
  (full yosys → nextpnr-ice40 → icepack → iceprog Makefile).
- **icestorm `examples/` directory** —
  https://github.com/YosysHQ/icestorm/tree/master/examples
  (minimal yosys+arachne+icepack flows for HX1K-EVB, iCEstick, etc.).
- **icebreaker-fpga / TinyFPGA-BX example repos** — board-specific
  Makefiles that show real PCF files and `iceprog -d` device strings.

## Board-specific cheat sheets
- **iCEstick (Lattice HX1K eval)** — `-d hx1k -P tq144`, `iceprog` works
  out of the box.
- **iCE40-HX8K Breakout** — `-d hx8k -P ct256`, set jumper J7 to
  "FLASH" before `iceprog`.
- **icebreaker (UP5K)** — `-d up5k -P sg48`, `iceprog` auto-detects.
- **TinyFPGA-BX (LP8K)** — uses `tinyprog` (separate tool), not `iceprog`.
