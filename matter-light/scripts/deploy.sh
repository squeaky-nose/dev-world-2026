#!/usr/bin/env bash
# Build and flash the firmware to a connected ESP32-C6 board.
#
# Usage:
#   ./deploy.sh            build and flash
#   ./deploy.sh monitor    build, flash, then open the serial monitor (Ctrl+] to exit)
#   ./deploy.sh erase      erase the board's flash entirely (wipes NVS/commissioning state)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# See Makefile comment: esp-matter main branch (not v1.2) against v6.0.2.
ESP_IDF_DIR="${ESP_IDF_DIR:-$HOME/.espressif/v6.0.2/esp-idf}"
ESP_MATTER_PATH="${ESP_MATTER_PATH:-$HOME/esp/esp-matter}"

if [ ! -f "$ESP_IDF_DIR/export.sh" ]; then
  echo "error: ESP-IDF not found at $ESP_IDF_DIR (set ESP_IDF_DIR to override)" >&2
  exit 1
fi
if [ ! -f "$ESP_MATTER_PATH/export.sh" ]; then
  echo "error: ESP-Matter not found at $ESP_MATTER_PATH (set ESP_MATTER_PATH to override)" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$ESP_IDF_DIR/export.sh" > /dev/null
export ESP_MATTER_PATH
# shellcheck source=/dev/null
source "$ESP_MATTER_PATH/export.sh" > /dev/null

# See Makefile comment: Homebrew's cmake 4.x breaks connectedhomeip's
# GN/ninja ExternalProject build. Use cmake 3.29.6 instead.
export PATH="$HOME/esp/cmake329-bin:$PATH"

# connectedhomeip's chip_gn build needs `gn` (and uses its own matched `ninja`),
# fetched into .environment/ by its own bootstrap: cd $ESP_MATTER_PATH/connectedhomeip/connectedhomeip && source scripts/bootstrap.sh
export PATH="$ESP_MATTER_PATH/connectedhomeip/connectedhomeip/.environment/cipd/packages/pigweed:$PATH"

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
echo "Using $port"

cd "$PROJECT_DIR"

# CMakeLists.txt reads IDF_TARGET before including project.cmake (the thing that
# would normally set it from sdkconfig), so a build dir without a cached target --
# e.g. after fullclean, or a fresh checkout -- fails with "Unsupported IDF_TARGET".
# One explicit set-target seeds CMakeCache.txt so later configures pick it up.
# rm -rf first: `idf.py set-target` runs its own fullclean, which refuses to touch
# build/ if it's non-empty but doesn't look like a complete CMake dir (e.g. leftover
# files from an earlier interrupted/failed configure with no CMakeCache.txt yet).
if [ ! -f "$PROJECT_DIR/build/CMakeCache.txt" ]; then
  rm -rf "$PROJECT_DIR/build"
  idf.py set-target esp32c6
fi

case "${1:-}" in
  monitor)
    idf.py -p "$port" flash monitor
    ;;
  erase)
    idf.py -p "$port" erase-flash
    ;;
  *)
    idf.py -p "$port" flash
    ;;
esac
