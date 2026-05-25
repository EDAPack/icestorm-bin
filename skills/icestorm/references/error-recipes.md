# icestorm failure recipes

## `iceprog`: "Can't find iCE FTDI USB device"
Symptom:
```
iceprog -- Simple programming tool for FTDI-based Lattice iCE programmers.
Trying to find iCE FTDI USB device ... Can't find iCE FTDI USB device (vendor_id 0x0403, device_id 0x6010).
ABORT.
```
Likely causes & fixes:
1. **No board attached** or the cable is data-less. Re-plug; verify
   the board enumerates: `lsusb | grep 0403`.
2. **`ftdi_sio` kernel module claimed the device** (Linux). Run
   `sudo modprobe -r ftdi_sio` for the session, or add a udev rule
   that detaches the driver (see `99-iceprog.rules` in the icestorm
   examples directory).
3. **Permission denied on the USB device**. Add the user to the
   `plugdev` group and ship a udev rule with `MODE="0666"`.
4. **macOS or Windows is using its own FTDI driver**. Install the
   libusb backend via `brew install libusb` (mac) or Zadig (Win).
5. **Wrong `-d` device-selector** if the board uses a non-standard
   VID/PID. List candidates with `lsusb` and try `-d i:<vid>:<pid>`.

## `iceprog`: "Operation timed out" mid-program
Symptom: programming starts, then halts with timeout.
Cause: noisy USB cable, brown-out, or the board's CRESET line being
held by another tool. Less commonly, the flash itself is failing.

Fix:
- Shorten the USB cable; try a different port.
- Confirm no other process owns the FTDI: `lsof /dev/bus/usb/...`.
- Try `iceprog -S` to load SRAM only; if that works, the flash chip
  is the problem.

## `icepack`: ASC parse error
Symptom:
```
icepack: design.asc:42: Failed to parse line
```
Cause: ASC was produced by an incompatible toolchain version (older
nextpnr against newer icestorm or vice versa), or the file is
truncated.
Fix: rebuild the ASC with the `nextpnr-ice40` from this same edapack
release; both packages are versioned together for compatibility.

## `icetime`: negative slack
Symptom: `Total path delay: 23.45 ns (42.65 MHz)` and your target was
50 MHz.
Cause: design is too slow on this device.
Fix:
- Pipeline the critical path printed by `-tmr`.
- Use a faster speed grade (`hx` > `lp`, `up` is its own class).
- Re-run `nextpnr-ice40` with a higher `--freq` constraint so the
  router fights harder.

## `icebox_vlog` produces empty / nonsense output
Symptom: output `.v` has nothing useful, or names like `unknown_NN`.
Cause: bitstream uses a feature icebox doesn't decode (typically newer
UltraPlus DSP/PLL features).
Fix: nothing to do programmatically — the icebox database is hand
maintained. For raw inspection use `icebox_explain` instead.

## `icemulti`: "image too large"
Symptom: combined bitstream rejected at `iceprog` time even though
each input fits the flash.
Cause: `-A` alignment padded images past the flash capacity.
Fix: drop or reduce `-A`; verify flash size with `iceprog -t`.
