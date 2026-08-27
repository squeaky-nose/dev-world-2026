#
#  Makefile
#  matter-light
#
#  Created by Sushant Verma on 27/8/2026 for [/dev/world 2026](https://devworld.au/)
#

# Build/flash workflow for the Embedded Swift Matter light firmware.

# NOTE: esp-matter release/v1.2 (matching swift-matter-examples' documented
# version) needs ESP-IDF v5.2.1, but v1.2's connectedhomeip pulls in a CIPD
# package (fuchsia/third_party/zap) gated behind Google/Fuchsia-internal auth
# that's not obtainable externally -- so this project tracks esp-matter's
# main branch against v6.0.2 instead. This means Matter.swift/Node.swift must
# match main's esp-matter API, not v1.2's (see comments at each call site).
ESP_IDF_DIR ?= $(HOME)/.espressif/v6.0.2/esp-idf
export ESP_MATTER_PATH ?= $(HOME)/esp/esp-matter

# Homebrew's cmake (4.x) generates broken ExternalProject step scripts for
# connectedhomeip's GN/ninja chip_gn build (WORKING_DIRECTORY + BINARY_DIR
# get concatenated into one bogus "cd path1;path2" shell command). Use
# cmake 3.29.6 instead -- isolated to just the cmake binary so it doesn't
# shadow ESP-IDF's own Python venv.
export PATH := $(HOME)/esp/cmake329-bin:$(PATH)

# connectedhomeip's chip_gn build needs `gn` (and uses its own matched `ninja`),
# fetched into .environment/ by its own bootstrap: cd $(ESP_MATTER_PATH)/connectedhomeip/connectedhomeip && source scripts/bootstrap.sh
export PATH := $(ESP_MATTER_PATH)/connectedhomeip/connectedhomeip/.environment/cipd/packages/pigweed:$(PATH)

# Only source export.sh (its Python dependency check is the slow part) when
# this shell doesn't already have an ESP-IDF environment active.
IDF_ENV := if [ -z "$$IDF_PATH" ]; then . "$(ESP_IDF_DIR)/export.sh" > /dev/null; fi
MATTER_ENV := if [ -z "$$ESP_MATTER_PATH" ] || [ ! -d "$$ESP_MATTER_PATH" ]; then echo "error: ESP_MATTER_PATH not set/found" >&2; exit 1; fi; . "$(ESP_MATTER_PATH)/export.sh" > /dev/null
# CMakeLists.txt reads IDF_TARGET before including project.cmake (the thing that
# would normally set it from sdkconfig), so a build dir without a cached target --
# e.g. after fullclean, or a fresh checkout -- fails with "Unsupported IDF_TARGET".
# One explicit set-target seeds CMakeCache.txt so later configures pick it up.
# rm -rf first: `idf.py set-target` runs its own fullclean, which refuses to touch
# build/ if it's non-empty but doesn't look like a complete CMake dir (e.g. leftover
# files from an earlier interrupted/failed configure with no CMakeCache.txt yet).
ENSURE_TARGET := if [ ! -f build/CMakeCache.txt ]; then rm -rf build && idf.py set-target esp32c6; fi

.PHONY: all help build flash monitor erase clean fullclean menuconfig

all: help

help:
	@echo "Available targets:"
	@echo "  make build        compile only"
	@echo "  make flash        build (if needed) and flash to a connected board"
	@echo "  make monitor      build, flash, and open the serial monitor (Ctrl+] to exit)"
	@echo "  make erase        erase the board's flash entirely (wipes NVS/commissioning state)"
	@echo "  make clean        remove build artifacts"
	@echo "  make fullclean    remove build artifacts and dependency cache"
	@echo "  make menuconfig   open the ESP-IDF configuration UI"

build:
	@$(IDF_ENV) && $(MATTER_ENV) && $(ENSURE_TARGET) && idf.py build

flash:
	@./scripts/deploy.sh

monitor:
	@./scripts/deploy.sh monitor

erase:
	@./scripts/deploy.sh erase

menuconfig:
	@$(IDF_ENV) && $(MATTER_ENV) && $(ENSURE_TARGET) && idf.py menuconfig

clean:
	@$(IDF_ENV) && $(MATTER_ENV) && idf.py clean

fullclean:
	@$(IDF_ENV) && $(MATTER_ENV) && idf.py fullclean
