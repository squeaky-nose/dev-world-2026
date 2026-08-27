#
#  Makefile
#  hello-morse
#
#  Created by Sushant Verma on 18/8/2026 for [/dev/world 2026](https://devworld.au/)
#

# Build/flash workflow for the hello-morse Embedded Swift firmware.

ESP_IDF_DIR ?= $(HOME)/.espressif/v6.0.2/esp-idf

# Only source export.sh (its Python dependency check is the slow part) when
# this shell doesn't already have an ESP-IDF environment active.
IDF_ENV := if [ -z "$$IDF_PATH" ]; then . "$(ESP_IDF_DIR)/export.sh" > /dev/null; fi

.PHONY: help build flash monitor clean fullclean menuconfig

.DEFAULT_GOAL := help

# Self-documenting targets: scans this Makefile for "target: ## description"
# lines and prints them, rather than maintaining a separate help text.
help: ## show this help
	@echo "Usage: make <target>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  %-12s %s\n", $$1, $$2}'

build: ## compile only, no board needed
	@$(IDF_ENV) && idf.py build

# idf.py flash/monitor already rebuild anything stale via ninja, so these
# don't depend on `build` -- that would pay for a second idf.py startup
# for no benefit.
flash: ## build (if needed) and flash to a connected board
	@./scripts/deploy.sh

monitor: ## build, flash, and open the serial monitor (Ctrl+] to exit)
	@./scripts/deploy.sh monitor

menuconfig: ## open the ESP-IDF configuration UI
	@$(IDF_ENV) && idf.py menuconfig

clean: ## remove build artifacts
	@$(IDF_ENV) && idf.py clean

fullclean: ## remove build artifacts and dependency cache
	@$(IDF_ENV) && idf.py fullclean
