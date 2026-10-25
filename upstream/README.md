# Upstream patch draft (NOT sent)

**In plain words:** this folder holds a ready-made patch that would add the
TUF GAMING X870-PRO WIFI7 W NEO to the official Linux driver, so that one day
nobody needs this package. Nothing here has been emailed or submitted.

## Files

| File | What it is |
|---|---|
| `0001-hwmon-asus-ec-sensors-add-TUF-GAMING-X870-PRO-WIFI7-.patch` | the patch, made with `git format-patch` against the **hwmon-next** tree (last commit to the driver file: `b67f60ae9b0b`) |
| `dsdt-tuf-x870-pro-wifi7-w-neo-bios1805.dat` | this board's ACPI DSDT table (binary, BIOS 1805). The driver's author asks for it with every new board so the ACPI mutex choice can be checked. It describes the firmware, not you; no serial numbers or other personal data were found in it. Delete it if you prefer not to publish it. |

## What the patch changes

Only two things, 11 added lines:

1. `drivers/hwmon/asus-ec-sensors.c`: a new `board_info_tuf_gaming_x870_pro_wifi7_w_neo`
   entry (CPU, CPU Package, Motherboard, VRM, CPU_Opt fan; AMD 800-series
   register layout; mutex `\_SB_.PCI0.SBRG.SIO1.MUT0`) and one line in the
   DMI board table. Both lists stay in alphabetical order (checked with the
   `scripts/check.sh` from github.com/zeule/asus-ec-sensors).
2. `Documentation/hwmon/asus_ec_sensors.rst`: the board name added to the
   list of supported boards.

It does **not** include this package's read-only change or the "N/A after
5 seconds" change. Kernel maintainers want one change per patch; a board
addition should not also change how the driver talks to the EC.

`scripts/checkpatch.pl --strict`: 0 errors, 0 warnings, 0 checks.

## The commit message, in plain English

> Adds the board. It uses the same EC layout and the same ACPI lock as the
> other X870 boards. The five sensors were compared with other Linux drivers
> on BIOS 1805 with a Ryzen 7 7800X3D: CPU Package matches the CPU's own
> temperature (k10temp) within 1-2 °C, CPU follows it about 10 °C lower,
> Motherboard equals the Super I/O's SYSTIN, VRM reads a normal 39-42 °C at
> idle, and the CPU_OPT fan reading follows the CPU fan speed setting and is
> not a copy of any other fan. T_Sensor is left out because nothing was
> plugged in to test it.

Below the `---` line there is a note for the maintainers (it would not end up
in the kernel history): the firmware on this board keeps the EC on bank 1 or
2 for up to two minutes at a time, and the current driver writes the bank
register on every poll, so they "fight" over it. The maintainers should
decide whether that needs a fix before or after adding the board.

**Be aware:** if this patch is merged as it is, the *kernel's* driver on this
board will write the EC bank register (as it does on every supported board).
This package does not.

## Credits for the patch

The driver is by Eugene Shalygin and the asus-ec-sensors contributors
(GPL-2.0+). The board entry was written by Eugene Flanagin, 2026. Register
addresses come from the kernel's own AMD 800-series table and were
cross-checked against LibreHardwareMonitor's public table (MPL-2.0; facts
only, no code). Full list: [../CREDITS.md](../CREDITS.md).

## How to send it later (when you decide to)

```sh
# 1. check it still applies to the latest hwmon-next
git clone --branch hwmon-next https://git.kernel.org/pub/scm/linux/kernel/git/groeck/linux-staging.git
cd linux-staging
git am /path/to/0001-hwmon-asus-ec-sensors-add-TUF-GAMING-X870-PRO-WIFI7-.patch
./scripts/checkpatch.pl --strict -g HEAD
./scripts/get_maintainer.pl -f drivers/hwmon/asus-ec-sensors.c

# 2. send with git send-email to the people get_maintainer.pl lists
#    (Eugene Shalygin, Guenter Roeck, linux-hwmon@vger.kernel.org)
```

The driver's author also accepts GitHub pull requests at
github.com/zeule/asus-ec-sensors (attach the DSDT `.dat`, sign off with a real
email) and forwards them to the kernel.
