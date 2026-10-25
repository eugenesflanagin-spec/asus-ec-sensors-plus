# Changelog

All notable changes to this project. Dates are YYYY-MM-DD.

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
