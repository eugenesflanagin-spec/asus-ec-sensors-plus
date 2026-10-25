#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
# Check that the board structs and the DMI board table in the driver are in
# alphabetical (C locale) order, as the kernel driver requires.
# Same idea as scripts/check.sh in github.com/zeule/asus-ec-sensors.
set -euo pipefail
f=${1:-module/asus-ec-sensors.c}
echo "Checking order of ec_board_info structs in $f"
grep 'static const struct ec_board_info board' "$f" | LC_COLLATE=C sort -c
echo "Checking order of DMI_EXACT_MATCH_ASUS_BOARD_NAME in $f"
grep -P '\tDMI_EXACT_MATCH_ASUS_BOARD_NAME' "$f" | sed 's/ /_/g' | LC_COLLATE=C sort -c
echo "Order OK."
