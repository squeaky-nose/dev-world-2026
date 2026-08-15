# Shop

A demo grocery app built twice — once in SwiftUI for iOS, once in Kotlin/Compose for Android — sharing a single Swift business-logic package, **shop-sdk**. The interesting part: the Android app doesn't reimplement the logic in Kotlin. It calls the *actual compiled Swift code* through JNI, cross-compiled to Android via the official [Swift SDK for Android](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html).

Both apps have two tabs — **Products** (filterable by tag, sortable by popularity/A–Z/Z–A) and **Cart** — plus a Product Detail screen. Product catalog, tag filtering, sorting, cart state, discount math, and checkout all live once, in Swift, in `shop-sdk`.

## Architecture

```
cart-app/
├── shop-sdk/                   SPM package — all business logic (Apple + Linux/Android)
├── shop-sdk-android-bridge/    SPM package — JNI glue, cross-compiles shop-sdk to libshopsdk.so
├── ios/                        SwiftUI app (xcodegen-generated Xcode project)
├── android/                    Kotlin/Compose app, calls shop-sdk via JNI
├── scripts/
│   └── build-shop-sdk-android.sh   cross-compiles + packages the .so into android/app/src/main/jniLibs/
└── Makefile                    clean/build/run for every component — see `make help`
```

`shop-sdk` and `shop-sdk-android-bridge` are deliberately **separate SPM packages**. `shop-sdk` is pure, cross-platform Swift (no Combine, no UIKit) — this is the only thing the iOS app links against, and it's also what gets cross-compiled for Android. `shop-sdk-android-bridge` depends on `shop-sdk` and adds the Android-only JNI surface (`@_cdecl` functions with JNI-mangled names, plus a small `CJNI` systemLibrary target wrapping the NDK's `jni.h`). Keeping them separate means a plain `swift build`/`swift test` on macOS never touches Android-only code.

The Android app's `ShopSdkBridge` object calls `nativeGetProducts`, `nativeAddToCart`, `nativeCheckout`, etc. — each one a JSON string in, JSON string out. All cart state lives inside the native Swift singleton; Kotlin just serializes calls in and parses JSON out.

## Business rules (implemented in `shop-sdk/Sources/ShopSDK/Cart/PricingEngine.swift`)

1. Per cart line: if quantity > 5, that line gets 10% off.
2. Promo code `devworld` takes 50% off the (already bulk-discounted) subtotal.
3. Shipping is $10, free if the merchandise total exceeds $30.
4. Checkout POSTs the cart (line items + totals + promo code) as JSON to a fixed endpoint.

57 products across four tags (fruit, vegetable, dairy, pantry), each with a real Wikipedia/Wikimedia Commons image, a description, recipe ideas, a price, and a hardcoded popularity score (0–1) — seeded in `shop-sdk/Sources/ShopSDK/Catalog/ProductCatalog.swift`. The Products screen filters by tag and sorts by popularity (default), A–Z, or Z–A, both driven entirely by `shop-sdk` — the dropdown option lists come from `ShopSDK.allTags()`/`allSortOptions()`, so neither app needed UI changes when dairy/pantry were added.

## Prerequisites

This project depends on a fairly involved native toolchain, especially for the Android leg. Run `make doctor` at any time to check what's missing.

**Required for everything:**
- macOS on Apple Silicon (arm64)
- [Homebrew](https://brew.sh)

**For `shop-sdk` (Swift business logic):**
- A Swift toolchain. This repo pins **Swift 6.3.3** via a `.swift-version` file (managed by [`swiftly`](https://www.swift.org/swiftly/)) — install swiftly, then `swiftly install 6.3.3`.

**For the iOS app:**
- A **full Xcode install** (not just the Command Line Tools) with iOS Simulator support — the App Store version is fine.
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen` (the `.xcodeproj` is generated from `ios/project.yml`, not checked in).
- The `XCODE_DEVELOPER_DIR` variable at the top of the `Makefile` points at a specific Xcode install path — override it (`make ios-build XCODE_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`) if yours lives somewhere else, or if your default `xcode-select` already points at a full Xcode you generally don't need to touch this.

**For the Android app (the heavy one):**
- A JDK (for Gradle) and [Gradle](https://gradle.org) on your `PATH`.
- The **Android SDK**, including `cmdline-tools` (`sdkmanager`), `platform-tools` (`adb`), and `emulator` + at least one AVD (this repo's Makefile defaults to an AVD named `Medium_Phone`).
- **Android NDK r27d or later.**
- The **Swift SDK for Android** bundle, matching your pinned Swift toolchain version.

None of this is auto-installed by the Makefile — toolchain setup is a deliberate one-time step, not something that should silently run (and re-download several GB) on every `make android-build`. See the bootstrap steps below.

### Bootstrapping the NDK + Swift SDK for Android

One-time setup, in order. Versions/URLs below were current as of this writing — always re-check [swift.org's Swift SDK for Android page](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html) and the [Android command-line tools page](https://developer.android.com/studio#command-line-tools-only) for the latest.

1. **Android `cmdline-tools`**, if you don't already have Android Studio / an SDK set up:
   ```bash
   mkdir -p ~/Library/Android/sdk/cmdline-tools
   curl -sSL -o /tmp/cmdline-tools.zip \
     "https://dl.google.com/android/repository/commandlinetools-mac-<build>_latest.zip"
   unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-extracted
   mkdir -p ~/Library/Android/sdk/cmdline-tools/latest
   mv /tmp/cmdline-tools-extracted/cmdline-tools/* ~/Library/Android/sdk/cmdline-tools/latest/
   ```

2. **Accept licenses and install the NDK** (r27d = revision `27.3.13750724`; run `sdkmanager --list | grep 'ndk;27'` to see what's current):
   ```bash
   export ANDROID_SDK_ROOT=~/Library/Android/sdk
   yes | ~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses
   ~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "ndk;27.3.13750724"
   ```

3. **Install the matching Swift toolchain via `swiftly`**, then the Android SDK bundle for that exact version:
   ```bash
   swiftly install 6.3.3
   swiftly use 6.3.3   # inside this repo, .swift-version already pins 6.3.3
   swift sdk install https://download.swift.org/swift-6.3.3-release/android-sdk/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE_android.artifactbundle.tar.gz \
     --checksum d160cc3206dd1886dae3fef2337af5e25ec034692cd0ec225721c56cc69da7f5
   swift sdk list   # confirm it registered as swift-6.3.3-RELEASE_android
   ```

4. **Link the NDK sysroot into the installed bundle** — the bundle ships a script for exactly this:
   ```bash
   export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.3.13750724
   bash ~/Library/org.swift.swiftpm/swift-sdks/swift-6.3.3-RELEASE_android.artifactbundle/swift-android/scripts/setup-android-sdk.sh
   ```

5. `make doctor` should now report everything present, and `make android-build` should work.

Note: the `.swift-version` file lives at `cart-app/.swift-version`, scoped to this repo only — it won't affect the Swift toolchain used by other projects on your machine.

## Quick start

```bash
make doctor        # check what's installed
make help          # list every target
```

| Component | Clean | Build | Test | Run |
|---|---|---|---|---|
| shop-sdk | `make shop-sdk-clean` | `make shop-sdk-build` | `make shop-sdk-test` | — |
| iOS | `make ios-clean` | `make ios-build` | `make ios-test` | `make ios-run` |
| Android | `make android-clean` | `make android-build` | `make android-test` | `make android-run` |
| Everything | `make clean-all` | | | |

`make ios-run` boots the configured Simulator (default `iPhone 17`) if needed and launches the app. `make android-run`/`make android-test` boot the configured AVD (default `Medium_Phone`) if no device is already attached. `android-build`/`android-run`/`android-test` all first cross-compile `shop-sdk` to `libshopsdk.so` via `scripts/build-shop-sdk-android.sh`, so there's no separate "build the bridge" step to remember.

## Testing

- `make shop-sdk-test` — 32 unit tests covering the pricing engine (bulk discount, promo code, shipping threshold), cart mutations, catalog/tag/sort integrity, and a live round-trip POST to the checkout endpoint.
- `make ios-test` — an XCUITest suite (`ios/ShopUITests/`) driving the real UI via the Filter/Sort dropdowns: (1) filter by tag, then mutate the cart, confirming the filter survives — guards against a regression where the product list's view model was rebuilt on every re-render, silently resetting the filter; (2) confirm the default sort is Popularity and that switching to A–Z reorders the list; (3) a full browse → add 6× an item (crosses the bulk-discount threshold) → add another → apply the `devworld` promo → checkout flow, asserting the exact computed totals along the way.
- `make android-test` — a Compose instrumented UI test suite (`android/app/src/androidTest/`) mirroring the iOS suite exactly: the same filter-persistence check, the same default-sort/A–Z check, and the same browse → cart → promo → checkout scenario, asserting the same computed totals. Because the native Swift cart singleton persists for the life of the app process (which instrumentation tests share across `@Test` methods), each test resets it via `ShopSdkBridge.nativeClearCart()` in an `@Before` step.
- Both platforms independently reach the same totals from the same cart scenario (6× Potatoes + 2× Tomatoes → $21.68, then $15.84 after the promo code) — the strongest evidence the shared Swift logic runs identically on both, not two separate implementations.

## Notes

- The checkout endpoint (see `ShopSDK.init(checkoutURL:)`) posts to a fixed URL that looks like an OAST/interactsh test domain rather than a real backend — that's intentional, wired up exactly as specified.
- Money math uses `Decimal` throughout `shop-sdk`; the Android JSON bridge carries values as plain JSON numbers, decoded as `Double` on the Kotlin side for display only (all arithmetic happens natively in Swift).
- Swift's `JSONEncoder` omits `nil` optional fields entirely (rather than emitting `null`), which the Kotlin DTOs account for via default values on optional fields (`promoCode`, `httpStatusCode`).
- **Wikimedia and User-Agents:** `upload.wikimedia.org` returns `HTTP 403` for requests carrying Coil's default OkHttp User-Agent — Wikimedia's [User-Agent policy](https://meta.wikimedia.org/wiki/User-Agent_policy) rejects generic/unidentified clients. `ShopApplication` (`android/app/src/main/kotlin/com/devworld/shop/ShopApplication.kt`) supplies a custom `ImageLoader` with an identifying User-Agent header to work around this. If product images stop loading again, check this first — Coil swallows load failures silently unless you attach a logger.
- **Disk-cached product images:** both apps persist fetched product images to disk so the catalog doesn't re-download 50+ images on every launch. Android configures Coil's `ImageLoader` with an explicit `DiskCache` (`ShopApplication.kt`, 250 MB, `cacheDir/image_cache`); iOS enlarges `URLCache.shared` (`ShopApp.swift`, 250 MB disk / 50 MB memory) since `AsyncImage` loads through `URLSession.shared`. Verified on Android by disabling Wi-Fi/data (`adb shell svc wifi disable` / `svc data disable`) and relaunching — previously-viewed product images still rendered.
