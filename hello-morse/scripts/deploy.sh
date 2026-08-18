#!/usr/bin/env bash
#
#  deploy.sh
#  hello-morse
#
#  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
#

# Build and flash the firmware to a connected ESP32-C6 board.
#
# Usage:
#   ./deploy.sh            build and flash
#   ./deploy.sh monitor    build, flash, then open the serial monitor (Ctrl+] to exit)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ESP_IDF_DIR="${ESP_IDF_DIR:-$HOME/.espressif/v6.0.2/esp-idf}"

if [ ! -f "$ESP_IDF_DIR/export.sh" ]; then
  echo "error: ESP-IDF not found at $ESP_IDF_DIR (set ESP_IDF_DIR to override)" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$ESP_IDF_DIR/export.sh" > /dev/null

candidates=(/dev/cu.usbmodem* /dev/cu.wchusbserial* /dev/cu.SLAB* /dev/cu.usbserial*)
ports=()
for p in "${candidates[@]}"; do
  [ -e "$p" ] && ports+=("$p")
done

if [ ${#ports[@]} -eq 0 ]; then
  echo "error: no board found. Plug in the ESP32-C6 via USB and try again." >&2
  exit 1
fi

if [ ${#ports[@]} -gt 1 ]; then
  echo "note: multiple serial devices found, using the first one:"
  printf '  %s\n' "${ports[@]}"
fi

port="${ports[0]}"
echo "Deploying to $port"

cd "$PROJECT_DIR"
if [ "${1:-}" = "monitor" ]; then
  idf.py -p "$port" flash monitor
else
  idf.py -p "$port" flash
fi
