#!/bin/sh
# Documentation-only example: shows the iceprog invocation an agent
# would run if a board were attached.  Running this file does NOT
# flash anything — it just prints the command and explains the flags.
set -e
cat <<'EOF'
# Program SPI flash on an iCEstick / HX1K-EVB / HX8K Breakout / icebreaker:
iceprog blinky.bin

# Program SRAM only (volatile, fast iteration loop):
iceprog -S blinky.bin

# If multiple FTDI boards are attached, disambiguate:
lsusb | grep 0403                       # find VID:PID
iceprog -d i:0x0403:0x6010:0 blinky.bin # first FT2232H

# Read flash back (useful for verifying or backing up a known-good image):
iceprog -r 0x20000 dump.bin             # read 128 KiB

# Verify flash matches a file without rewriting it:
iceprog -c blinky.bin

# After programming, the device reboots automatically; no further
# command is needed.
EOF
