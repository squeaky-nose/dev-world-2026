# hello-morse

See [Blinking an LED on the ESP32](https://docs.swift.org/embedded/documentation/embedded/esp32guide) for documentation on this example.

## Prerequisites

- [ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/get-started/index.html) installed at `~/.espressif/v6.0.2/esp-idf`. Be sure to update espressif version as needed in Makefile and deploy.sh

- ESP-IDF's one-time setup script must have been run, to create its Python virtual environment:
  ```
  cd ~/.espressif/v6.0.2/esp-idf && ./install.sh esp32c6
  ```

## Quick start

```
make build     # compile only, no board needed
make flash     # build (if needed) and flash to a connected board
make monitor   # build, flash, and open the serial monitor (Ctrl+] to exit)
```

Run `make` (or `make help`) to list all available targets.

## How the Makefile works

The [Makefile](Makefile) is a thin wrapper around `idf.py` and [`scripts/deploy.sh`](scripts/deploy.sh):

- `ESP_IDF_DIR` points at your ESP-IDF checkout (default `~/.espressif/v6.0.2/esp-idf`,
  see Prerequisites above). Override it inline if yours lives elsewhere:
  ```
  make build ESP_IDF_DIR=/path/to/esp-idf
  ```
- Every target sources `$ESP_IDF_DIR/export.sh` before running `idf.py`, but only if
  `IDF_PATH` isn't already set in your shell — so it's cheap to run repeatedly even
  inside an existing ESP-IDF environment.
- `flash` and `monitor` call `scripts/deploy.sh` directly instead of depending on
  `build`, since `idf.py flash`/`monitor` already rebuild anything stale themselves;
  that avoids paying for a second `idf.py` startup.
- `clean` removes build artifacts but keeps the `build/` directory and CMake cache;
  `fullclean` removes the whole `build/` directory. Neither touches
  `managed_components/` (the component-manager's dependency cache) — delete that
  manually with `rm -rf managed_components` if you need to.
