# 01-pack

Intent: end-to-end iCE40 HX1K flow producing a real bitstream and a
timing report. Demonstrates how icestorm sits at the end of the
yosys/nextpnr chain.

Prereqs: `yosys`, `nextpnr-ice40`, `icepack`, `icetime` all on PATH
(install `yosys-bin` and `nextpnr-bin` from this same release).

```
./run.sh
```

Outputs:
- `blinky.json` — gate-level netlist from yosys.
- `blinky.asc` — placed/routed design from nextpnr.
- `blinky.bin` — bitstream ready for `iceprog`.
- console: post-route timing summary from `icetime -tmr`.
