# icestorm CLI cheatsheet

Condensed reference for the binaries shipped in `icestorm-bin/bin/`.

## Tools you'll actually call

| Tool | One-line purpose | Typical input | Typical output |
|---|---|---|---|
| `icepack` | ASC ↔ bitstream | `.asc` | `.bin` |
| `iceprog` | flash/SRAM programmer (FTDI MPSSE) | `.bin` | device |
| `icetime` | post-route static timing | `.asc` | text report |
| `icebox_vlog` | decompile bitstream to Verilog | `.asc` | `.v` |
| `icebox_explain` | annotate ASC with human names | `.asc` | text |
| `icebox_asc2hlc` | dump high-level config of an ASC | `.asc` | text |
| `icebox_diff` | structural diff of two ASCs | two `.asc` | text |
| `icebox_hlc2asc` | high-level config → ASC (rare) | text | `.asc` |
| `icebox_stat` | tile/resource counts | `.asc` | text |
| `icemulti` | combine bitstreams for warmboot | N × `.bin` | `.bin` |
| `iceunpack` | alias of `icepack -u` | `.bin` | `.asc` |

## Devices supported by `icetime -d`

`lp384` · `lp1k` · `lp4k` · `lp8k` · `hx1k` · `hx4k` · `hx8k` ·
`up3k` · `up5k` · `u4k`

(`-d` for `iceprog` is a *device-selector string*, not a part code —
don't confuse the two.)

## Packages supported by `icetime -P`

`tq144` · `vq100` · `cb81` · `cb121` · `cb132` · `cm36` · `cm49` ·
`cm81` · `cm121` · `cm225` · `ct256` · `bg121` · `sg48` · `qn32` ·
`uwg30`

Pick the package printed on the part. Wrong package only affects pin
delays; gate delays are accurate regardless.

## `iceprog` device strings (`-d`)

Format: `i:<vid>:<pid>[:<index>]` or `s:<vid>:<pid>:<serial>`.

| String | Used for |
|---|---|
| `i:0x0403:0x6010:0` | First FT2232H (HX8K-CT256 breakout, iCEstick variants). |
| `i:0x0403:0x6014` | FT232H (icebreaker, single-channel). |
| `s:0x0403:0x6010:iCE40HX1K-EVB` | Disambiguate by USB serial. |

`lsusb` (Linux) or `system_profiler SPUSBDataType` (macOS) shows
available VID/PID/serial.
