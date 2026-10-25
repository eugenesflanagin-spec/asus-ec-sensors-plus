#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
#
# ec-sample.sh - READ-ONLY look at the ASUS embedded controller (EC) sensor
# registers, side by side with sensors Linux already has (k10temp, Super I/O).
# Use it to check that the EC values make sense on your board, or to help add
# a new board.
#
# It reads /sys/kernel/debug/ec/ec0/io, which needs the ec_sys module loaded
# with write support OFF:
#     sudo modprobe ec_sys write_support=0
# The script refuses to run if ec_sys was loaded with write_support=1.
# It never writes anything anywhere.
#
# Usage:  sudo ./ec-sample.sh [count] [seconds-between]      (default 20 x 2 s)
#         sudo ./ec-sample.sh dump                             (one hex dump)
set -u

IO=/sys/kernel/debug/ec/ec0/io
WS=/sys/module/ec_sys/parameters/write_support

[ "$(id -u)" = 0 ] || { echo "run with sudo (debugfs is root-only)"; exit 1; }
[ -r "$WS" ] || { echo "ec_sys is not loaded. Run: sudo modprobe ec_sys write_support=0"; exit 1; }
[ "$(cat "$WS")" = "N" ] || { echo "ec_sys was loaded WITH write support. Refusing. Run: sudo rmmod ec_sys; sudo modprobe ec_sys write_support=0"; exit 1; }
[ -r "$IO" ] || { echo "$IO not found (is debugfs mounted?)"; exit 1; }

if [ "${1:-}" = dump ]; then
  xxd "$IO"
  exit 0
fi

hw() { for d in /sys/class/hwmon/hwmon*; do [ "$(cat "$d/name")" = "$1" ] && { echo "$d"; return; }; done; }
milli() { [ -r "$1" ] && echo $(( $(cat "$1") / 1000 )) || echo "-"; }
K=$(hw k10temp)
N=$(hw nct6799); [ -z "$N" ] && N=$(hw nct6798); [ -z "$N" ] && N=$(hw nct6701)
P=$(hw prom21_xhci)

echo "EC bank 0 registers (signed degrees C, fan in RPM) | reference sensors from other drivers"
echo "time      bank  0x30  0x31  0x32  0x33  0x35  0x36  fan@b0 | Tctl  SYSTIN  PROM21"
echo "                CPU   Pkg   MB    VRM   (T_Sensor?)        | k10temp  SuperIO  chipset"
for _ in $(seq 1 "${1:-20}"); do
  b=$(xxd -p -c256 "$IO")
  byte() { printf "%d" "0x${b:$(( 2 * $1 )):2}"; }
  s8() { local v; v=$(byte "$1"); [ "$v" -gt 127 ] && v=$(( v - 256 )); echo "$v"; }
  bank=$(byte 0xff)
  if [ "$bank" != 0 ]; then
    printf "%s  %-4s  (EC is on bank %s right now: these bytes are not the sensors, skipped)\n" "$(date +%T)" "$bank" "$bank"
  else
    printf "%s  %-4s  %-4s  %-4s  %-4s  %-4s  %-4s  %-4s  %-6s | %-4s  %-6s  %s\n" "$(date +%T)" "$bank" \
      "$(s8 0x30)" "$(s8 0x31)" "$(s8 0x32)" "$(s8 0x33)" "$(s8 0x35)" "$(s8 0x36)" \
      "$(( $(byte 0xb0) * 256 + $(byte 0xb1) ))" \
      "$(milli "$K/temp1_input")" "$(milli "${N:-/nonexistent}/temp1_input")" "$(milli "${P:-/nonexistent}/temp1_input")"
  fi
  sleep "${2:-2}"
done
