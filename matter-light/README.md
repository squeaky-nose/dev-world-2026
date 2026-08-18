# esp32-led-blink-sdk

See [Blinking an LED on the ESP32](https://docs.swift.org/embedded/documentation/embedded/esp32guide) for documentation on this example.

## Prerequisites

- [ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/get-started/index.html) installed at `~/.espressif/v6.0.2/esp-idf`. Be sure to update espressif version as needed in Makefile and deploy.sh

- ESP-IDF's one-time setup script must have been run, to create its Python virtual environment:
  ```
  cd ~/.espressif/v6.0.2/esp-idf && ./install.sh esp32c6
  ```

- [esp-matter](https://github.com/espressif/esp-matter) pinned to the exact commit below (see
  Versions), cloned with its `connectedhomeip` submodule, at `~/esp/esp-matter` — with
  `ESP_MATTER_PATH` pointing at it (defaulted in the Makefile). One-time setup:
  ```
  mkdir -p ~/esp/esp-matter && cd ~/esp/esp-matter
  git init
  git remote add origin https://github.com/espressif/esp-matter.git
  git fetch --depth 1 origin c5b9ea8afd2aaa6edd19b9fc8a8cfe682304c7db
  git checkout FETCH_HEAD
  git submodule update --init --depth 1
  cd connectedhomeip/connectedhomeip && ./scripts/checkout_submodules.py --shallow --platform esp32 linux
  source scripts/bootstrap.sh   # fetches gn/ninja into .environment/
  ```
  Note: this specific esp-matter commit off `main` (not the `release/v1.2` tag
  swift-matter-examples documents) is required here, since v1.2 needs an authenticated
  Google/Fuchsia-internal CIPD login (for the ZAP tool) that isn't obtainable externally.
  `Matter.swift`/`Node.swift` are written against this commit's esp-matter API, not v1.2's —
  a newer `main` commit may have moved the API again, so don't just track `main`.

- cmake 3.29.6 at `~/esp/cmake329-bin/cmake` — Homebrew's cmake 4.x breaks connectedhomeip's
  GN/ninja build (see comment in [Makefile](Makefile)). Download from
  [Kitware's releases](https://github.com/Kitware/CMake/releases/tag/v3.29.6) and place just
  the `cmake` binary (with its `../share/cmake-3.29` resources alongside it) at that path.

## Versions

Exact versions this project is currently built and tested against:

| Component | Version |
|---|---|
| ESP-IDF | [v6.0.2](https://github.com/espressif/esp-idf/tree/v6.0.2) |
| esp-matter | `main` @ [`c5b9ea8`](https://github.com/espressif/esp-matter/commit/c5b9ea8afd2aaa6edd19b9fc8a8cfe682304c7db) (2026-08-06) |
| connectedhomeip (esp-matter's submodule) | [`efefc94f`](https://github.com/project-chip/connectedhomeip/commit/efefc94fee39d8d1fbbc3c27b9d7fc9025095887) (2026-07-09) |
| Swift | Apple Swift 6.5-dev, `main-snapshot-2026-05-18` (see [.swift-version](.swift-version)) |
| cmake (workaround build) | 3.29.6 |
| gn (via connectedhomeip's Pigweed bootstrap) | 2255 (`97b68a0bb62b`) |
| ninja (via connectedhomeip's Pigweed bootstrap) | 1.13.0.git.fuchsia |
| Target board | Seeed XIAO ESP32C6 (4MB flash) |

Managed components resolved via the IDF Component Manager (see [dependencies.lock](dependencies.lock)):

| Package | Version |
|---|---|
| espressif/button | 4.2.0 |
| espressif/cjson | 1.7.19~2 |
| espressif/cmake_utilities | 1.1.1 |
| espressif/esp_delta_ota | 1.1.4 |
| espressif/esp_encrypted_img | 2.7.0 |
| espressif/esp_secure_cert_mgr | 2.9.3 |
| espressif/led_strip | 3.0.3 |
| espressif/mdns | 1.11.3 |

## Quick start

```
make build     # compile only, no board needed
make flash     # build (if needed) and flash to a connected board
make monitor   # build, flash, and open the serial monitor (Ctrl+] to exit)
```

Run `make` (or `make help`) to list all available targets.

## Pairing the device

1. Flash and watch the boot log:
   ```
   make monitor
   ```
2. Look for these lines shortly after boot:
   ```
   I (...) chip[SVR]: SetupQRCode: [MT:Y.K9042C00KA0648G00]
   I (...) chip[SVR]: https://project-chip.github.io/connectedhomeip/qrcode.html?data=MT%3AY.K9042C00KA0648G00
   I (...) chip[SVR]: Manual pairing code: [34970112332]
   ```
   These values are fixed by this firmware's compiled-in discriminator/passcode config, not
   randomly generated per boot, so they stay the same across resets and reflashes.
3. In a Matter controller app (Apple Home, Google Home, Alexa, a Matter test controller, etc.),
   choose "Add device" and either:
   - **Scan the QR code**: open the `qrcode.html?data=...` URL from the log in a browser to
     render it, then scan with the controller app, or
   - **Enter the manual code**: pick "Enter setup code manually" and type the 11-digit code.

The device advertises commissioning over BLE (CHIPoBLE) until it's joined a Wi-Fi network as
part of the commissioning flow, so it doesn't need to be pre-connected to your network.

## Resetting the device

```
make erase     # wipe the board's flash entirely (bootloader, partition table, app, NVS)
make flash     # firmware must be reflashed afterward -- erase-flash wipes everything, not just NVS
```

This clears the Matter fabric/commissioning state stored in NVS, so the device shows up as
uncommissioned again and can be paired fresh (with the same QR/manual code as above, since
those aren't derived from NVS state).

## Remote logging

[`RemoteLogger`](main/RemoteLog.swift) posts on/off state changes and polls for remote commands
over plain HTTP, using URLs hardcoded in [Main.swift](main/Main.swift:8-9):

```swift
let remoteLogger = RemoteLogger(
  pollURL: "https://m8jrbrlmd4.rbmock.dev/",  // GET
  logURL: "https://m8jrbrlmd4.rbmock.dev/log")  // POST
```

`pollURL` is a **GET** endpoint, hit every 5s to check whether logging is currently enabled
(`RemoteLogger.poll()`). `logURL` is a **POST** endpoint, hit with a JSON body whenever the
light's on/off state changes while logging is enabled (`RemoteLogger.logStateChange(on:)`).
Both bodies are built/parsed with [cJSON](https://github.com/DaveGamble/cJSON) (already a
resolved dependency via esp-matter, see Versions), not hand-rolled string handling.

`pollURL`'s response must be a JSON object with an `"enabled"` boolean field, e.g.:
```json
{"enabled": true}
```
If the field is missing, not a JSON boolean, or the response fails to parse as JSON at all,
`RemoteLogger` leaves the previously-known `loggingEnabled` value unchanged.

Each `logURL` POST body is a JSON object shaped like:
```json
{"state": "on", "uptime_ms": 12345}
```

These currently point at a [RequestBin](https://requestbin.net) mock endpoint, viewable at:
https://requestbin.net/bins/mock/1af750ca-a85f-4ee2-b0e2-a572e7799f7f

**This bin is tied to one person's account and isn't a shared/permanent endpoint.** Anyone
building this project should replace `pollURL`/`logURL` in `Main.swift` with their own
endpoint (e.g. a fresh RequestBin, or a real logging server) before relying on remote logging —
otherwise state changes go nowhere useful, or leak into someone else's bin.

**If you're using a RequestBin mock for `pollURL`,** its configured mock response must be
updated to return a JSON object like `{"enabled": true}` (or `{"enabled": false}`) instead of
freeform text — `RemoteLogger.poll()` now parses the response as JSON rather than
substring-matching "true"/"false" anywhere in the raw text.

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
