# Credits and sources

This project is a small change on top of other people's work. This page lists
every source that was used, what was taken from it, and under which licence.

## 1. The Linux kernel driver `asus-ec-sensors` (code, GPL)

The module in `module/asus-ec-sensors.c` **is** the Linux kernel driver, copied
and then changed a little.

| | |
|---|---|
| File | `drivers/hwmon/asus-ec-sensors.c` |
| Tree | hwmon-next, `git://git.kernel.org/pub/scm/linux/kernel/git/groeck/linux-staging.git`, branch `hwmon-next` (branch head `e1b3c2630d5b` on 2026-10-25) |
| Last commit to the file | `b67f60ae9b0b8eeb1bd29eb73da050bbe761250a` "hwmon: (asus-ec-sensors) add ROG STRIX Z490-A GAMING" |
| Mainline equivalent | Linux 7.3 (torvalds tree, last file commit `6ee0d3de9568`); hwmon-next only adds two more boards |
| Original author | Eugene Shalygin `<eugene.shalygin@gmail.com>` (Copyright (C) 2021), plus everyone who added boards over the years (see `git log drivers/hwmon/asus-ec-sensors.c` in the kernel) |
| Hwmon maintainer | Guenter Roeck |
| Licence | `GPL-2.0+` (SPDX line in the file, kept unchanged) |

The original copyright header is kept. Our changes are marked in the header
("Modified by Eugene Flanagin, 2026 ...") and with `plus` comments in the
code. What we changed:

1. Added the board **TUF GAMING X870-PRO WIFI7 W NEO** (one `ec_board_info`
   struct, one DMI table line).
2. For boards whose sensors are all in EC bank 0 (this board, and every
   AMD 800-series board), the EC is only **read**, never written. The original
   bank-switching code is kept, renamed `asus_ec_block_read_banked()`, and is
   used only for boards that need sensors from other banks.
3. Values older than 5 seconds are reported as "no data" (N/A) instead of old
   numbers.
4. `MODULE_VERSION` added so you can see which build is loaded.

The out-of-tree copy of the same driver by its author was also read for the
DKMS layout ideas and the order-check script:
[github.com/zeule/asus-ec-sensors](https://github.com/zeule/asus-ec-sensors),
commit `33ac3ac4dc63` (2026-10-08), GPL-2.0. No code from that repo is in this
project other than what is identical to the kernel file. Its
`CONTRIBUTING.md` describes how to add a board (DSDT mutex hunt, `-40` blank
value); we followed it.

The kernel documentation file `Documentation/hwmon/asus_ec_sensors.rst`
(hwmon-next, same commit) is changed only in the upstream patch draft.

## 2. LibreHardwareMonitor (facts only, MPL-2.0)

| | |
|---|---|
| Project | [LibreHardwareMonitor](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor) |
| File | `LibreHardwareMonitorLib/Hardware/Motherboard/Lpc/EC/EmbeddedController.cs` |
| Commit read | `23b559ee7af04f3802395e7256027f58a17bb6c2` (2026-10-18) |
| Licence | MPL-2.0 |

**No code was copied.** Only facts were used, to cross-check the kernel's
numbers:

- the AMD 800-series EC register addresses: CPU `0x30`, CPU Package `0x31`,
  Motherboard `0x32`, VRM `0x33`, T Sensor `0x36` (alternate `0x35`),
  CPU Optional Fan `0xB0` (2 bytes), and the blank value `-40` for an
  unplugged temperature header. These match the kernel table.
- that the sibling board **TUF GAMING X870-PLUS WIFI** exposes VRM and
  CPU_OPT fan through the EC.

Issues and pull requests in that project used as evidence:

| Link | Who / when | What we learned |
|---|---|---|
| [#2432](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/issues/2432) "ASUS TUF GAMING X870-PRO WIFI7 W NEO: Incorrect temperature readings" | Oscar-Rod, opened 2026-07-14 | Same board as ours. Its Super I/O chip is a Nuvoton NCT6701D; several Super I/O temperature inputs are not connected (they show random numbers). HWiNFO and LHM show a T_Sensor and fans from the Super I/O. |
| [PR #2417](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/pull/2417) "Fix NCT6701D + add three mainboards" | Blacktempel, merged 2026-08-11 | Adds this board's Super I/O mapping. VRM is *not* in that mapping for this board, so the EC is the place to get VRM temperature. |
| [#2106](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/issues/2106) / [PR #2121](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/pull/2121) | elbubi (2025-12-11) / Rem0o (merged 2026-01-03) | The sibling TUF GAMING X870-PLUS WIFI: EC gives VRM temperature and CPU_OPT fan; confirmed by the user against HWiNFO. |
| [#2377](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/issues/2377) | matarus-theron, 2026-05-17 | On another X870 board the chipset (Promontory) temperature is also missing from the EC: the AMD 800 EC layout has no known chipset register. |

## 3. Other evidence

| Source | What it gave |
|---|---|
| [zeule/asus-ec-sensors issue #69](https://github.com/zeule/asus-ec-sensors/issues/69) "AMD 800 Series Motherboards" (leuchtrakete666, 2025-06-01, comments by zeule, SethBarberee, freevatar and others) | Other X870E owners see T_Sensor = -59 / -62 °C with nothing plugged in. We see -62 at `0x35` too, which is why T_Sensor is left out. |
| This PC's own ACPI tables (DSDT, BIOS 1805), read with `iasl` | The EC is `\_SB_.PCI0.SBRG.EC0`; the mutex `\_SB_.PCI0.SBRG.SIO1.MUT0` exists; the ASUS `BREC` method is an empty stub (so the driver's direct `ec_read` is the only way). A binary copy is in `upstream/dsdt.dat`. |
| Linux kernel drivers `k10temp`, `nct6775` (nct6799), `prom21_xhci` | Reference values the EC numbers were compared with. |
| ASUS BIOS manual E25269 "AMD 800 Series BIOS manual", section 7 "Monitor menu", page 94 | The list of sensors the BIOS shows on this family (CPU, CPU Package, MotherBoard, VRM, Chipset, T_Sensor, DIMM A/B; CPU fan, CPU optional fan, chassis fans, AIO pump). Used to name what the EC might hold. |
| The board's own BIOS 1805 HII string database (dumped locally) | Names the firmware knows: `CPU_OPT`, `AIO_PUMP`, `W_PUMP+`, `T_SENSOR`, `W_IN`/`W_OUT`, `Chipset 1`/`Chipset 2`. These strings are shared by the whole 800-series firmware, so they do not prove which headers this board has. |

## 4. AM5 chipset facts (PROM21 count per chipset)

Used for the "chipset temperature" section of the README:

- [Socket AM5 - Wikipedia](https://en.wikipedia.org/wiki/Socket_AM5)
- [X670E vs X670 vs B650E vs B650 - Digital Citizen](https://www.digitalcitizen.life/x670e-x670-b650e-b650-chipsets/)
- [X870, X870E, B850 and B840 boards for AMD: differences and release dates - HWCooling](https://hwcooling.net/en/x870-x870e-b850-and-b840-boards-for-amd-differences-and-release-dates)
- [AM5 PROM21 chipset technical information revealed - WePC](https://www.wepc.com/news/am5-prom21-chipset-technical-information-revealednbspnbsp/)

## 5. Licence of this project

The project as a whole is distributed under **GPL-2.0-only** (see `LICENSE`).
The driver file keeps its original `GPL-2.0+` (GPL-2.0-or-later) notice, which
allows this. Scripts and packaging written for this project are GPL-2.0-only.
