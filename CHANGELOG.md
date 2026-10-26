# Changelog

All notable changes to this project. Dates are YYYY-MM-DD.

## [0.1.2] - 2026-10-26

### Changed
- `bank_switch` is now a number with an automatic default:
  - `-1` / `auto` (**new default**): bank switching on for boards flagged
    `.plus_bank_switch` (firmware known to park the EC on another bank for
    minutes), off for every other board;
  - `0` (also `n`/`N`/`off`): never write to the EC, as before;
  - `1` (also `y`/`Y`/`on`): always on, as before.
  Any other value is refused and the module does not load.
- **Behaviour change on the TUF GAMING X870-PRO WIFI7 W NEO:** it is the one
  flagged board, so bank switching is now on by default there (no
  `/etc/modprobe.d` file needed). Use `bank_switch=0` for the old strictly
  read-only default. Every other board keeps the read-only default.
- `/sys/module/asus_ec_sensors/parameters/bank_switch` now shows `-1`, `0`
  or `1` instead of `Y`/`N`. Existing `bank_switch=1` config files keep
  working unchanged.
- The kernel log says at load time which mode was chosen
  (`EC bank switching on (bank_switch=-1, auto)`).
- Package description no longer says "read-only": it reads only, with an
  optional save/restore of the bank-select register `0xFF`.
- README: `bank_switch` value table, 0.1.2 test results, safety notes and
  "Add your board" (when to set `.plus_bank_switch`); example modprobe file
  updated.

### Unchanged
- The only register the driver can write is still the bank register `0xFF`
  (set to 0, then the saved value written back), under the firmware's ACPI
  mutex. Fans, PWM, voltages and settings are never written.

## [0.1.1] - 2026-10-25

### Added
- `bank_switch` module parameter (default off). With `bank_switch=1`, if the
  firmware has left the EC on another bank, the driver switches the bank
  register `0xFF` to 0 for the poll and writes the original value back,
  under the firmware's ACPI mutex, like the kernel's own driver and
  LibreHardwareMonitor. No other register is ever written. On the TUF
  GAMING X870-PRO WIFI7 W NEO this gives values on every poll (310 of 310
  in a 19-minute test) instead of long N/A periods.
- `examples/asus-ec-sensors-plus.conf`: optional `/etc/modprobe.d` file that
  turns it on (installed as an example only, not active by default).

### Changed
- README: how and when to use `bank_switch`, test results, safety notes.

## [0.1.0] - 2026-10-25

First release.

### Added
- ASUS **TUF GAMING X870-PRO WIFI7 W NEO** support in the `asus-ec-sensors`
  driver: CPU (`0x30`), CPU Package (`0x31`), Motherboard (`0x32`),
  VRM (`0x33`) temperatures and the CPU_OPT fan (`0xB0`), AMD 800-series
  layout, ACPI mutex `\_SB_.PCI0.SBRG.SIO1.MUT0`. Tested on BIOS 1805 with a
  Ryzen 7 7800X3D.
- Read-only EC access for boards whose sensors are all in EC bank 0: the
  bank register is read before and after each poll and never written; a poll
  is skipped if the firmware has the EC on another bank.
- Values older than 5 seconds are reported as N/A (`-ENODATA`).
- `MODULE_VERSION` (`0.1.0-plus`) so the loaded build can be identified.
- DKMS packaging (`module/dkms.conf`), automatic `LLVM=1` for clang-built
  kernels, Arch `PKGBUILD`, `tools/build-local-pkg.sh`.
- `tools/ec-sample.sh`: read-only EC sampler for checking boards
  (refuses to run if `ec_sys` has write support enabled).
- Draft upstream kernel patch in `upstream/` (not sent).
- GitHub Actions workflow: builds against the current Arch kernel headers,
  install-tests the package with DKMS in a fresh container, and attaches it to
  the release on `v*` tags.

### Known issues
- The board's firmware keeps the EC on bank 1 (once bank 2) for seconds to
  minutes at a time, also with no driver loaded. In an 18-minute watch on
  2026-10-25 the EC was on bank 0 only about 54 % of the time (8 periods
  away from bank 0, median 20 s, longest 115 s), and right after that it
  stayed on bank 1 for more than 30 minutes, including 20 minutes with
  nothing reading the EC at all. During those periods all
  sensors show N/A. Not suitable for logging or fan control.
- T_Sensor not enabled (could not be tested; nothing plugged in).
