# asus-ec-sensors-plus

**In plain words:** your ASUS motherboard has a small helper chip (the
"embedded controller", EC) that knows some temperatures Linux normally can't
see, most importantly the **VRM** (the power circuit that feeds the CPU).
Linux has a driver for this chip, `asus-ec-sensors`, but it only knows a list
of boards. This project is that driver **plus extra ASUS boards** that are not
in the kernel yet, packaged so DKMS builds it for every kernel you install.
The first added board is the **ASUS TUF GAMING X870-PRO WIFI7 W NEO**; more
can be added (see [Add your board](#11-add-your-board)). After installing,
`sensors` shows a new block called `asusec-isa-000a`.

It is **read-only** on every board whose sensors sit in EC bank 0 (all
AMD 800-series boards): it only ever reads from the EC, never writes to it,
and never touches fans or fan control.

Example (TUF GAMING X870-PRO WIFI7 W NEO):

```
asusec-isa-000a
Adapter: ISA adapter
CPU_Opt:      858 RPM
CPU:          +54.0°C
CPU Package:  +66.0°C
Motherboard:  +22.0°C
VRM:          +40.0°C
```

**Status: experimental.** The values are right when they are there, but on
the TUF X870-PRO they are often **N/A for minutes at a time**, because the firmware
keeps the EC busy and this build refuses to interrupt it. Read
[Known limitations](#8-known-limitations) first.

Version 0.1.0. Licence GPL-2.0-only (the driver file keeps its original
GPL-2.0-or-later notice). See [CREDITS.md](CREDITS.md) for where everything
came from.

---

## Contents

1. [Supported hardware](#1-supported-hardware)
2. [What each sensor is and how it was checked](#2-what-each-sensor-is-and-how-it-was-checked)
3. [Chipset (PROM21) temperature](#3-chipset-prom21-temperature)
4. [Install on Arch Linux](#4-install-on-arch-linux)
5. [Install on other distributions (generic DKMS)](#5-install-on-other-distributions-generic-dkms)
6. [Check that it works](#6-check-that-it-works)
7. [Uninstall](#7-uninstall)
8. [Known limitations](#8-known-limitations)
9. [Troubleshooting](#9-troubleshooting)
10. [Safety notes](#10-safety-notes)
11. [Add your board](#11-add-your-board)
12. [Upstream status](#12-upstream-status)
13. [Credits](#13-credits)
14. [Glossary](#14-glossary)

---

## 1. Supported hardware

Boards **added by this project** (not in the kernel driver yet):

| Board (exact DMI `board_name`) | BIOS tested | Sensors | Validated by |
|---|---|---|---|
| `TUF GAMING X870-PRO WIFI7 W NEO` | 1805 (Ryzen 7 7800X3D) | CPU, CPU Package, Motherboard, VRM, CPU_Opt fan | Eugene Flanagin, 2026-10-25: side-by-side with k10temp, nct6799, prom21_xhci; idle + desktop use only ([details](#2-what-each-sensor-is-and-how-it-was-checked)) |

Want yours here? See [Add your board](#11-add-your-board).

Find your board name with:

```sh
cat /sys/class/dmi/id/board_name
```

The module also contains every board the normal kernel driver already
supports (ROG, ProArt, Prime, TUF X670E ...). Those keep working exactly as
with the kernel's own driver, except that boards whose sensors are all in
EC bank 0 (every AMD 800-series board) also get the read-only behaviour
described in [Safety notes](#10-safety-notes). If your board is already
supported by your kernel, you do not need this package.

**Module name.** The module is still called `asus_ec_sensors` (file
`asus-ec-sensors.ko`), the same as the kernel's own. That is on purpose: DKMS
installs it in `updates/dkms/`, which the kernel always prefers, so exactly one
copy loads and nothing has to be blacklisted. A differently named module would
load *next to* the kernel's one on boards both know, and the two would fight
over the same device. Check which one is loaded with
`cat /sys/module/asus_ec_sensors/version` (this one says `...-plus`).

---

## 2. What each sensor is and how it was checked

**Short version:** five sensors are on, all checked against other Linux
drivers. T_Sensor is off because it could not be checked.

| `sensors` name | What it measures | EC register | Checked against | Result | Confidence |
|---|---|---|---|---|---|
| `CPU Package` | CPU temperature as reported to the board | `0x31` (1 byte, °C) | `k10temp` Tctl | follows Tctl within 1-2 °C, idle 41-50, busy desktop 65-69 | High |
| `CPU` | a second, lower CPU reading (ASUS's "CPU" in the BIOS) | `0x30` (1 byte, °C) | `k10temp` Tctl | moves with Tctl, about 10 °C lower (32-58 °C) | High (that it is CPU); medium (which exact CPU point) |
| `Motherboard` | board temperature | `0x32` (1 byte, °C) | Super I/O `nct6799` SYSTIN | same value (22-24 °C) | High |
| `VRM` | CPU power-stage temperature | `0x33` (1 byte, °C) | nothing else on Linux reads it | 39-42 °C at idle and light use, which is normal; the sibling TUF X870-PLUS WIFI uses the same register | Medium-high (plausible, not cross-checked under heavy load) |
| `CPU_Opt` | fan on the CPU_OPT header | `0xB0`-`0xB1` (2 bytes, RPM) | Super I/O fans and CPU fan duty | 520-1270 RPM, rises and falls with the CPU fan's PWM, matches none of the 7 Super I/O fan inputs | High (if a fan or pump is on CPU_OPT) |
| T_Sensor | 2-pin thermistor header | `0x35` (reads -62) / `0x36` (reads 0) | - | nothing was plugged in, so it could not be checked | **Not enabled** |

"Checked against" means the numbers were read side by side, at the same
moment, from the EC and from other drivers, at idle and during normal desktop
use. No stress tests or benchmarks were run.

Other EC readings that exist but are **not** exposed, because nobody knows
yet what they are:

| Register | Value seen | Notes |
|---|---|---|
| `0x41` | 47 steady | possibly the BIOS's "Chipset Temperature" (it is not the same as `prom21_xhci`, which reads 51-55) - unconfirmed |
| `0x42` | same as `0x30` | copy of CPU |
| `0x51`, `0x55` | 38-40, close to VRM | maybe copies of VRM - unconfirmed |
| `0x6A` | -40 | -40 is the usual "nothing connected" value |
| `0xF0`-`0xF1` | 500-750, changing | looks like an RPM value (little-endian), not matching any fan exactly |
| `0xF2` | 52 steady | unknown |
| `0xF3`, `0xF4` | changing | unknown |
| bank 1 `0x00`-`0x07` | 33-39 °C | temperature-like values, unknown which (DIMMs? the BIOS also shows DIMM A/B temperatures) |
| bank 1 and bank 2 | see [Known limitations](#8-known-limitations) | firmware uses these banks itself |

The BIOS **Monitor** page (ASUS AMD 800-series BIOS manual E25269, section 7
"Monitor menu", page 94) lists: CPU, CPU Package, MotherBoard, VRM, Chipset,
T_Sensor, DIMM A and DIMM B temperatures; CPU fan, CPU optional fan, chassis
fans and AIO pump speeds; CPU core, 12 V, 5 V, 3.3 V and CPU VDDIO/MC
voltages. Of those, this package adds CPU, CPU Package, MotherBoard, VRM and
CPU optional fan. DIMM temperatures already come from Linux's `spd5118`
driver; the chipset from `prom21_xhci` (see section 3); fans other than
CPU_OPT and all voltages from the Super I/O (`nct6799` block).

Water in / water out / water flow, CPU current and CPU core voltage are not
known for the AMD 800-series EC layout (neither the kernel nor
LibreHardwareMonitor lists them for any 800-series board).

The **Super I/O chip** (Nuvoton NCT6701D, driven by Linux's `nct6775` driver
and shown as `nct6799-isa-0290`) gives the CPU fan, chassis fans, pump, the
voltages and SYSTIN/CPUTIN. Several of its AUXTIN temperature inputs are not
wired to anything on this board and show random numbers (for example +84 °C
or +1 °C). Ignore those; this is not caused by this package.

---

## 3. Chipset (PROM21) temperature

**Short version:** the chipset temperature does not come from the EC. Linux
already shows it as `prom21_xhci`.

AMD's AM5 chipsets are built from one or two **Promontory 21 (PROM21)** chips.
Each PROM21 has a USB controller with a temperature sensor, and the in-kernel
driver `prom21_xhci` (Linux 7.3+) reads it. One `prom21_xhci` block appears
per chip:

```sh
sensors 'prom21_xhci-*'
```

| Chipset | PROM21 chips | What you will see |
|---|---|---|
| X870E, X670E, X670 | 2 | two `prom21_xhci` blocks (chip #1, chip #2) |
| X870, B850, B650E, B650 | 1 | one `prom21_xhci` block |
| A620 | 1 (cut-down PROM21) | one block, if its USB controller is the PROM21 one |
| B840 | 1 (PROM21 per most sources; one says Promontory 19 - unconfirmed) | probably one |
| boards without an AMD chipset chip | 0 | none (nothing breaks) |

The TUF GAMING X870-PRO WIFI7 W NEO has one PROM21 (PCI `1022:43fc` USB
controller at `0b:00.0`), reading 53-55 °C at idle. This package does not
change or replace `prom21_xhci`; it is listed here because people look for a
"chipset" reading in the EC and there is none on AMD 800-series boards.
Sources for the table are in [CREDITS.md](CREDITS.md#4-am5-chipset-facts-prom21-count-per-chipset).

---

## 4. Install on Arch Linux

You need the headers for each kernel you use (`linux-headers`,
`linux-zen-headers`, your custom kernel's headers ...).

**From a release** (when there is one on GitHub):

```sh
sudo pacman -U asus-ec-sensors-plus-dkms-0.1.0-1-any.pkg.tar.zst
```

**From this git checkout:**

```sh
tools/build-local-pkg.sh --install
```

That packs the current commit, runs `makepkg`, and installs the package with
`sudo pacman -U`. Pacman's DKMS hook then builds the module for every
installed kernel that has headers.

Load it now (after a reboot it loads by itself, because the module knows the
board's DMI name):

```sh
sudo modprobe asus_ec_sensors
```

Kernels built with clang (for example linux-tkg "llvm" or CachyOS) are
detected automatically and the module is built with `LLVM=1`.

No `modprobe.d` file and no blacklist are needed: the kernel's own copy of
the driver does not know this board, and DKMS installs this copy in
`updates/dkms/`, which the kernel prefers.

---

## 5. Install on other distributions (generic DKMS)

Install `dkms`, a compiler, `make`, and the kernel headers first:

| Distribution | Command |
|---|---|
| Debian / Ubuntu | `sudo apt install dkms build-essential linux-headers-$(uname -r)` |
| Fedora | `sudo dnf install dkms kernel-devel kernel-headers` |
| openSUSE | `sudo zypper install dkms kernel-default-devel` |

Then, from this checkout:

```sh
VER=$(cat module/VERSION)
sudo cp -r module /usr/src/asus-ec-sensors-plus-$VER
sudo dkms add     -m asus-ec-sensors-plus -v $VER
sudo dkms build   -m asus-ec-sensors-plus -v $VER
sudo dkms install -m asus-ec-sensors-plus -v $VER
sudo modprobe asus_ec_sensors
```

If your kernel enforces signed modules (Secure Boot), DKMS on Debian/Ubuntu
signs with its MOK key; enrol it once with `sudo mokutil --import
/var/lib/dkms/mok.pub` and reboot.

To build by hand without DKMS (for testing): `cd module && make && sudo
insmod asus-ec-sensors.ko`.

---

## 6. Check that it works

```sh
sensors 'asusec-*'
```

You should see the five sensors from section 2. Make sure it is this build
and not the kernel's own:

```sh
cat /sys/module/asus_ec_sensors/version   # 0.1.0-plus
modinfo -n asus_ec_sensors                 # .../updates/dkms/asus-ec-sensors.ko...
sudo dmesg | grep asus-ec                  # "board has 5 EC sensors that span 6 registers"
```

If a value says `N/A` for a few seconds now and then, that is expected; see
the next section.

---

## 7. Uninstall

Arch:

```sh
sudo modprobe -r asus_ec_sensors
sudo pacman -R asus-ec-sensors-plus-dkms
```

Generic DKMS:

```sh
sudo modprobe -r asus_ec_sensors
sudo dkms remove -m asus-ec-sensors-plus -v 0.1.0 --all
sudo rm -r /usr/src/asus-ec-sensors-plus-0.1.0
```

Once your kernel has the board itself (see [Upstream status](#12-upstream-status)),
uninstall this package and the kernel's own driver takes over.

---

## 8. Known limitations

**The firmware sometimes keeps the EC busy on another "bank".** The EC has
several pages ("banks") of registers; the sensors are on bank 0. On this
board the BIOS firmware itself switches the EC to bank 1 or bank 2 and leaves
it there for anything from a few seconds to about two minutes, even with no
driver loaded (seen with only a read-only monitor running). The kernel's own
driver handles that by switching the bank back to 0 (a write to the EC) and
then back again. This package does not write, so while the EC is on another
bank it simply waits:

- for up to 5 seconds it keeps showing the last good values,
- after that, every sensor shows **N/A** until the EC is back on bank 0
  (that can be many minutes).

On the test PC, in an 18-minute watch, the EC was on bank 0 only about
**54 %** of the time: 8 periods away from bank 0, typically about 20 seconds,
up to about 2 minutes. After that it stayed on bank 1 for **more than
25 minutes** in one go (14:28 to at least 14:55), and that included 15
minutes in which nothing at all was reading the EC (driver and `ec_sys`
unloaded, checked with single reads afterwards), so it is not caused by
reading. In an earlier 5-minute stretch it never left bank 0, so it comes
and goes. So: good for looking at temperatures now and then,
**not** good enough for logging or fan curves.

**Why not just switch the bank like everyone else?** The kernel's own
driver, LibreHardwareMonitor and (as far as is known) HWiNFO all do it:
write 0 to the bank register, read, write the old bank back, while holding
the firmware's lock. That is the normal way and would give values all the
time. This build deliberately does not, because it was made under a strict
"never write to the EC" rule. If you are comfortable with that one write,
the kernel's own driver will do it once this board is added upstream (see
`upstream/`).

**Do not use these readings for fan control** (CoolerControl, fancontrol,
fan2go ...) yet. Those tools will see the new `asusec` sensors automatically;
leave them on the Super I/O or k10temp sensors.

**T_Sensor** is not enabled (see section 2).

---

## 9. Troubleshooting

| What you see | Why | What to do |
|---|---|---|
| No `asusec-*` block in `sensors` | module not loaded | `sudo modprobe asus_ec_sensors`, then `sudo dmesg \| grep asus-ec` |
| `modprobe: FATAL: Module asus_ec_sensors not found` | DKMS did not build for this kernel (no headers) | install the headers for your kernel, then `sudo dkms autoinstall` |
| `dmesg`: `Failed to get hardware access guard` or `mutex` error | different BIOS with a different ACPI mutex name | report it; try `sudo modprobe asus_ec_sensors mutex_path=:GLOBAL_LOCK` |
| Loaded, but `sensors` shows only some boards' sensors / the wrong ones | the kernel's own copy loaded instead of this one | `modinfo -n asus_ec_sensors` must point to `updates/dkms`; run `sudo depmod -a` and reload |
| `version` file missing or not `-plus` | same as above | same as above |
| All values `N/A` | firmware has the EC on another bank right now | wait; it comes back (section 8). If it never does, report it with `sudo dmesg` output |
| DKMS build fails with clang errors on a clang-built kernel | `clang`/`lld` not installed | install `clang` and `lld` (the Makefile adds `LLVM=1` itself) |
| `Required key not available` when loading | Secure Boot needs signed modules | sign with your MOK key (section 5) |
| Huge or random temperatures in `nct6799` AUXTIN lines | unused Super I/O inputs on this board | ignore; not related to this package |
| After a kernel update the sensors are gone | DKMS rebuild failed | `dkms status`; check `/var/lib/dkms/asus-ec-sensors-plus/*/build/make.log` |

---

## 10. Safety notes

- **Read-only on this board.** On boards whose sensors all sit in EC bank 0
  (this one and every AMD 800-series board), the module only uses the
  kernel's `ec_read()`; the bank-switch write of the original driver is not
  used. You can check this in `module/asus-ec-sensors.c`, function
  `asus_ec_block_read()`.
- For older boards that need other banks (some X570/X670E boards' water
  sensors), the original kernel code path is kept unchanged, and that path
  does write the EC bank register, exactly like the kernel driver.
- The module takes the same ACPI mutex the firmware uses
  (`\_SB_.PCI0.SBRG.SIO1.MUT0`), like the kernel driver.
- It does not control fans, change voltages, or touch the Super I/O.
- The helper script `tools/ec-sample.sh` is read-only too: it refuses to run
  unless `ec_sys` was loaded with `write_support=0`.
- Never load `ec_sys` with `write_support=1` while experimenting. A wrong
  write to the EC can stop fans or change power settings.

---

## 11. Add your board

**In plain words:** you read the EC's numbers (read-only), compare them with
sensors Linux already has, and send the evidence. Nothing in this guide writes
to the EC.

**What you need:** an ASUS board, the name from
`cat /sys/class/dmi/id/board_name` (vendor must be `ASUSTeK COMPUTER INC.`),
and the `iasl` tool (Arch: `acpica`).

1. **Find your board's EC layout and lock.**
   - The family is set by the chipset: AMD 800-series (X870E/X870/B850/B840)
     use the same registers as this board; AMD 600, 500, Intel boards differ
     (see the `sensors_family_*` tables in `module/asus-ec-sensors.c`).
   - Dump and decompile the ACPI DSDT:
     `sudo cat /sys/firmware/acpi/tables/DSDT > dsdt.dat && iasl -d dsdt.dat`.
     In `dsdt.dsl` look for the EC device (`PNP0C09`) and for a `Mutex`
     inside `Device (SIO1)` (on this board `\_SB_.PCI0.SBRG.SIO1.MUT0`). If
     there is none, the driver can use `:GLOBAL_LOCK`.
2. **Read the EC, read-only.**
   ```sh
   sudo modprobe ec_sys write_support=0
   sudo tools/ec-sample.sh 30 2      # 30 samples, 2 s apart
   sudo tools/ec-sample.sh dump      # one full hex dump of the current bank
   sudo rmmod ec_sys
   ```
   The script refuses to run if write support is on. Never load `ec_sys`
   with `write_support=1`.
3. **Match each register to a real sensor.** For every register you want to
   add, show it next to something independent, sampled at the same moment:
   - CPU / CPU Package vs `k10temp` Tctl (should follow it);
   - Motherboard vs the Super I/O SYSTIN (`nct67xx` block);
   - fans vs the BIOS Monitor page or the Super I/O fan inputs (a CPU_OPT fan
     usually follows the CPU fan's PWM);
   - VRM: plausible idle value (30-55 °C) and, if you are willing, a rise
     under load; there is usually nothing else on Linux to compare with;
   - T_Sensor: plug a 10 kΩ thermistor into T_SENSOR; unplugged headers read
     -40 or -62.
   Comparing with the BIOS Monitor page or with HWiNFO's "ASUS EC" section on
   Windows is also good evidence. No stress test is needed; idle plus normal
   use is fine. Watch the `bank` column: if it is not 0, skip that sample.
4. **Add the board** (keep both lists alphabetical; check with
   `tools/check-order.sh`): one `static const struct ec_board_info
   board_info_<name>` entry and one `DMI_EXACT_MATCH_ASUS_BOARD_NAME(...)`
   line in `module/asus-ec-sensors.c`, then a row in the table in
   [Supported hardware](#1-supported-hardware).
5. **Test**: `cd module && make && sudo insmod asus-ec-sensors.ko` (unload
   any loaded copy first with `sudo rmmod asus_ec_sensors`), then
   `sensors 'asusec-*'` and `sudo dmesg | grep asus-ec`.
6. **Send** a pull request or an issue with:
   - `board_name`, BIOS version, CPU;
   - the `ec-sample.sh` output and the reference sensors you compared with;
   - which registers you added and how confident you are in each;
   - the mutex path you used and where in the DSDT you found it;
   - the binary `dsdt.dat` (not the decompiled text), if you are OK sharing it;
   - a `Signed-off-by:` line with a real email, so the board can go upstream.

Every board added here should also be sent to the kernel driver (see
[Upstream status](#12-upstream-status)); once it is merged there, the row
moves out of this project.

---

## 12. Upstream status

A patch adding this board to the kernel driver is drafted in
[`upstream/`](upstream/) (plain-English explanation in
[`upstream/README.md`](upstream/README.md)). It has **not** been sent yet.
Once it is merged into a released kernel, this package is no longer needed.

---

## 13. Credits

- The driver: **Eugene Shalygin** and the contributors to the Linux
  `asus-ec-sensors` driver (GPL). This project is that driver plus one board
  and a read-only change.
- Register facts cross-checked with **LibreHardwareMonitor** (MPL-2.0; facts
  only, no code).
- Board evidence from LibreHardwareMonitor issue #2432 (Oscar-Rod) and PR
  #2417 (Blacktempel), and zeule/asus-ec-sensors issue #69.

Full list with links, commits, dates and licences: [CREDITS.md](CREDITS.md).

---

## 14. Glossary

| Word | Meaning |
|---|---|
| **EC (embedded controller)** | a small microcontroller on the motherboard that handles fans, power buttons and some sensors. The OS talks to it through I/O ports 0x62/0x66. |
| **EC register** | one numbered byte inside the EC, e.g. `0x33` holds the VRM temperature. |
| **Bank** | the EC has more registers than fit in one page of 256, so register `0xFF` picks which page ("bank") you are looking at. |
| **VRM** | voltage regulator module: the power stages around the CPU socket that turn 12 V into CPU voltage. They get warm under load; 40-80 °C is normal. |
| **Tctl** | the CPU temperature AMD reports (via `k10temp`). |
| **Super I/O** | another chip (here a Nuvoton NCT6701D) that reads most fans and voltages; Linux driver `nct6775`. |
| **PROM21** | AMD Promontory 21, the chip that makes up the AM5 chipset (one or two per board). |
| **DMI** | the board's identity tables; the module checks `board_name` to know which board it is on. |
| **DKMS** | Dynamic Kernel Module Support: rebuilds this module automatically for every new kernel. |
| **hwmon** | the Linux framework for hardware sensors; `sensors` reads it. |
| **ACPI mutex** | a lock in the BIOS tables; the driver takes it so it does not talk to the EC at the same time as the firmware. |
| **DSDT** | the main ACPI table from the BIOS; it describes the EC and the mutex. |
| **N/A** | "no data": shown when the value could not be read recently. |
| **upstream** | the official Linux kernel. |
