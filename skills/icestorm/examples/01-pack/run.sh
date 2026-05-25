#!/bin/sh
# Full HX1K (iCEstick) flow: yosys → nextpnr-ice40 → icepack → icetime.
# Requires yosys-bin and nextpnr-bin on PATH (sibling edapack packages).
# Does NOT run iceprog — see ../02-program.
set -e
cd "$(dirname "$0")"

yosys -q -p 'read_verilog blinky.v; synth_ice40 -top blinky -json blinky.json'
nextpnr-ice40 --hx1k --package tq144 --json blinky.json --pcf blinky.pcf --asc blinky.asc --quiet
icepack blinky.asc blinky.bin
echo "--- icetime report ---"
icetime -d hx1k -P tq144 -tmr blinky.asc | tail -20
ls -l blinky.bin
