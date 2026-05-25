---
name: icestorm
description: Project IceStorm — bitstream tooling for Lattice iCE40 FPGAs. Pack ASCII placement (`.asc`) into a real bitstream (`.bin`), program the device (`iceprog`), estimate post-route timing (`icetime`), unpack bitstreams for inspection (`icebox`), and combine multiple bitstreams (`icemulti`).
license: ISC
version: "2024.06"
---

# icestorm — Agent Skill

## When to use this skill
- You have an `.asc` from `nextpnr-ice40` and need a `.bin` to load onto
  silicon. Reach for `icepack`.
- You need to flash an iCE40-HX/LP/UP/UltraPlus board over USB/SPI.
  Reach for `iceprog`.
- A user asks "will this design meet timing on iCE40?" without running
  a full STA flow. Reach for `icetime`.
- You want to inspect what a bitstream actually does (which tiles,
  which LUT inits). Reach for `icebox`/`iceunpack`.
- You want to load multiple images into one SPI flash for cold-boot
  reconfiguration (warmboot). Reach for `icemulti`.

Do **not** use icestorm to *generate* a design from RTL — that's
`yosys` (synth) + `nextpnr-ice40` (place & route). icestorm is the
back-end after PnR.

## Core mental model
IceStorm is a **family of small CLIs**, each operating on a fixed file
format in the iCE40 flow:

```
   .v / .sv          .json           .asc           .bin
   ───────► yosys ─────────► nextpnr ───────► icepack ──────► iceprog ─► chip
                                           │
                                           ├──► icetime  (timing report)
                                           └──► icebox*  (inspect/unpack)
```

Every tool takes the file format of the previous stage. There is no
"project" or driver — agents stitch tools together with shell
redirection or `make`/dv-flow.

## Quick start
```sh
# Pack a routed design (from nextpnr-ice40) into a bitstream.
icepack design.asc design.bin

# Then write it to an attached board (default: HX1K/HX8K dev boards).
iceprog design.bin
```

## Common tasks
- **Pack ASC → bitstream →** `icepack in.asc out.bin`
- **Unpack bitstream → ASC (for inspection) →** `icepack -u in.bin out.asc`
- **Program board (auto-detect FTDI) →** `iceprog design.bin`
- **Program a specific interface →** `iceprog -d i:0x0403:0x6010:0 design.bin`
- **Read flash back to file →** `iceprog -r 0x10000 dump.bin` (read 64 KiB)
- **Erase flash only →** `iceprog -e 32` (erase first 32 KiB)
- **Program SRAM only (no flash, lost on power cycle) →** `iceprog -S design.bin`
- **Post-route timing report →** `icetime -d hx8k -P ct256 -tmr design.asc`
- **Inspect a bitstream →** `icebox_vlog -d hx8k design.asc > design.v`
  (decompiles routing to a structural Verilog netlist; great for "what
  did the tools actually build?")
- **Combine 2–4 bitstreams for warmboot →**
  `icemulti -o multi.bin -p0 boot.bin app1.bin app2.bin app3.bin`

## Tool-by-tool flag reference (essentials)

### `icepack`
| Flag | Effect |
|---|---|
| `-u` | Unpack: bitstream `.bin` → `.asc`. |
| `-s` | Read/write SRAM-style bitstream (.bin format used by `iceprog -S`). |
| `-B`/`-b` | Select bram-init / config-flash layouts (rare; consult `icepack --help`). |

### `iceprog`
| Flag | Effect | When |
|---|---|---|
| `-d <devstring>` | Pick FTDI device by USB VID:PID:if (e.g. `i:0x0403:0x6010:0`). | Multiple boards attached. |
| `-I [ABCD]` | Pick MPSSE interface on a multi-channel FTDI chip. | Custom boards. |
| `-S` | Program SRAM only (volatile, fast). | Iterate quickly. |
| `-r <N>` | Read `N` bytes from flash to stdout / output file. | Backup. |
| `-c` | Check (read back and compare). | Verify a flash. |
| `-e <KiB>` | Erase the first `<KiB>` kilobytes. | Clean a flash. |
| `-o <offset>` | Start at byte `<offset>` (hex OK). | Multi-image layouts. |
| `-t` | Just probe and report flash ID. | Sanity check. |

### `icetime`
| Flag | Effect |
|---|---|
| `-d <part>` | Device: `lp384`/`lp1k`/`lp4k`/`lp8k`/`hx1k`/`hx4k`/`hx8k`/`up3k`/`up5k`/`u4k`. |
| `-P <pkg>` | Package: `tq144`, `ct256`, `cm225`, etc. — affects pin timing only. |
| `-c <MHz>` | Target clock; tool reports slack against this. |
| `-tmr` | Print a topological max-delay report. |
| `-r <file>` | Write detailed timing report to file. |
| `-p <pcf>` | Read pin constraint file (so io-buffer delays are correct). |

### `icebox_*` helpers
- `icebox_vlog` — decompile ASC to readable Verilog.
- `icebox_explain` — annotate ASC with human-readable tile/wire names.
- `icebox_asc2hlc` — high-level config dump.

### `icemulti`
| Flag | Effect |
|---|---|
| `-o <file>` | Output combined bitstream. |
| `-p <N>` | Set the *power-on* image index (0–3). |
| `-c` | Coldboot mode (use full reset on switch). |
| `-A <align>` | Force per-image alignment (power-of-2 KB). |

## Failure recipes
| Symptom (stderr) | Likely cause | Fix |
|---|---|---|
| `iceprog: Can't find iCE FTDI USB device` | No board attached, wrong driver bound (Linux: `ftdi_sio` claimed it), or permission. | Unbind `ftdi_sio` (`sudo modprobe -r ftdi_sio`) or add a udev rule; on macOS/Windows, use the libusb driver. |
| `iceprog: Operation timed out` | Cable issue, dev board not in programming mode (RESET held low), or SPI flash absent. | Check connector orientation, try `iceprog -S` to bypass flash. |
| `icepack: design.asc:NN: ...` | ASC was generated against a different chip than the icepack expects. | Verify `--device` you passed to `nextpnr-ice40` matches your board; re-route. |
| `icetime` reports negative slack | Design too slow for requested freq. | Lower `-c` to find achievable freq; profile critical path in the `-tmr` report. |
| `icebox_vlog` output gibberish | Bitstream uses a tile shape icebox doesn't know (newer/older silicon). | Update icestorm; not all UltraPlus features are decoded. |

## Interop with edapack
- **Upstream**: `yosys` (synth_ice40 → `.json`) → `nextpnr-ice40` (PnR
  → `.asc`) → `icepack` (`.asc` → `.bin`). The full flow lives across
  three packages; this one closes the loop into silicon.
- **Sibling**: `nextpnr-bin` consumes the iCE40 chipdb that this
  package's source repo produces during build, but the chipdb is
  shipped *with* nextpnr — no runtime dependency between the two
  packages.

## References
See `references/docs-index.md` and `references/cli-cheatsheet.md`.

## Examples
- `examples/01-pack/` — given a stub `.asc`, run `icepack` and inspect
  the result.
- `examples/02-program/` — what an `iceprog` invocation looks like
  (does **not** flash; the script prints the command rather than
  running it, because no board is attached in CI).
