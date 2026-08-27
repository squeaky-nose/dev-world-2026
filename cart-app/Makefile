#
#  Makefile
#  cart-app
#
#  Created by Sushant Verma on 27/8/2026 for [/dev/world 2026](https://devworld.au/)
#

.DEFAULT_GOAL := help

# --- Overridable configuration ---------------------------------------------
XCODE_DEVELOPER_DIR ?= /Applications/Xcode-27.0.0-Beta.4.app/Contents/Developer
IOS_SIMULATOR_NAME  ?= iPhone 17
IOS_BUNDLE_ID       ?= com.devworld.shop
IOS_DERIVED_DATA    := $(CURDIR)/ios/DerivedData

ANDROID_HOME         ?= $(HOME)/Library/Android/sdk
ANDROID_NDK_HOME     ?= $(ANDROID_HOME)/ndk/27.3.13750724
ANDROID_AVD_NAME     ?= Medium_Phone
ANDROID_BUNDLE_ID    ?= com.devworld.shop

export ANDROID_NDK_HOME

# -----------------------------------------------------------------------------
.PHONY: help
help: ## Show this help
	@echo "Usage: make <target>"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- shop-sdk ----------------------------------------------------------------
.PHONY: shop-sdk-clean shop-sdk-build shop-sdk-test

shop-sdk-clean: ## Remove shop-sdk build artifacts
	rm -rf shop-sdk/.build shop-sdk-android-bridge/.build

shop-sdk-build: ## Build shop-sdk (macOS/iOS, pure Swift target)
	cd shop-sdk && swift build

shop-sdk-test: ## Run shop-sdk unit tests
	cd shop-sdk && swift test

# --- iOS -----------------------------------------------------------------
.PHONY: ios-clean ios-build ios-run ios-test

ios-clean: ## Remove the generated Xcode project and DerivedData
	rm -rf ios/Shop.xcodeproj ios/Generated "$(IOS_DERIVED_DATA)"

ios-build: ## Generate the Xcode project and build the iOS app for Simulator
	cd ios && xcodegen generate
	cd ios && DEVELOPER_DIR=$(XCODE_DEVELOPER_DIR) xcodebuild \
		-project Shop.xcodeproj -scheme Shop \
		-destination 'platform=iOS Simulator,name=$(IOS_SIMULATOR_NAME)' \
		-derivedDataPath "$(IOS_DERIVED_DATA)" \
		build

ios-run: ios-build ## Build and launch the iOS app in Simulator
	@export DEVELOPER_DIR=$(XCODE_DEVELOPER_DIR); \
	UDID=$$(xcrun simctl list devices | grep "$(IOS_SIMULATOR_NAME) (" | grep -oE '[0-9A-F-]{36}' | head -1); \
	if [ -z "$$UDID" ]; then echo "No simulator named '$(IOS_SIMULATOR_NAME)' found"; exit 1; fi; \
	xcrun simctl boot "$$UDID" 2>/dev/null || true; \
	xcrun simctl bootstatus "$$UDID" -b; \
	xcrun simctl install "$$UDID" "$(IOS_DERIVED_DATA)/Build/Products/Debug-iphonesimulator/Shop.app"; \
	xcrun simctl launch "$$UDID" $(IOS_BUNDLE_ID)

ios-test: ## Generate the Xcode project and run the XCUITest end-to-end flow
	cd ios && xcodegen generate
	cd ios && DEVELOPER_DIR=$(XCODE_DEVELOPER_DIR) xcodebuild \
		-project Shop.xcodeproj -scheme Shop \
		-destination 'platform=iOS Simulator,name=$(IOS_SIMULATOR_NAME)' \
		-derivedDataPath "$(IOS_DERIVED_DATA)" \
		test

# --- Android -----------------------------------------------------------------
.PHONY: android-clean android-build android-run android-test

define android_ensure_device
	export ANDROID_HOME=$(ANDROID_HOME); \
	export PATH="$(ANDROID_HOME)/platform-tools:$$PATH"; \
	if [ -z "$$(adb devices | awk 'NR>1 && $$2=="device" {print $$1}')" ]; then \
		echo "Booting $(ANDROID_AVD_NAME)..."; \
		nohup "$(ANDROID_HOME)/emulator/emulator" -avd $(ANDROID_AVD_NAME) -no-snapshot-load -no-boot-anim \
			> /tmp/shop-android-emulator.log 2>&1 & \
		adb wait-for-device; \
		while [ "$$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do sleep 2; done; \
	fi
endef

android-clean: ## Remove Android/Gradle build artifacts and the cross-compiled .so's
	rm -rf android/app/build android/build android/.gradle android/.kotlin
	rm -rf android/app/src/main/jniLibs
	rm -rf shop-sdk-android-bridge/.build

android-build: ## Cross-compile shop-sdk for Android and assemble the debug APK
	./scripts/build-shop-sdk-android.sh
	cd android && ANDROID_HOME=$(ANDROID_HOME) gradle assembleDebug

android-run: android-build ## Build and launch the Android app (boots the AVD if needed)
	@$(android_ensure_device); \
	cd android && ANDROID_HOME=$(ANDROID_HOME) gradle installDebug; \
	adb shell am start -n $(ANDROID_BUNDLE_ID)/.MainActivity

android-test: android-build ## Cross-compile shop-sdk, then run instrumented Compose UI tests (boots the AVD if needed)
	@$(android_ensure_device); \
	cd android && ANDROID_HOME=$(ANDROID_HOME) gradle connectedDebugAndroidTest

# --- Global --------------------------------------------------------------
.PHONY: clean-all doctor

clean-all: shop-sdk-clean ios-clean android-clean ## Clean everything (shop-sdk, iOS, Android)

doctor: ## Check that required tools/toolchains are installed
	@echo "-- Swift --"
	@command -v swift >/dev/null && swift --version | head -1 || echo "MISSING: swift"
	@swift sdk list 2>/dev/null | grep -q android && echo "OK: Swift SDK for Android installed" || echo "MISSING: Swift SDK for Android (swift sdk install ...)"
	@echo "-- iOS --"
	@[ -d "$(XCODE_DEVELOPER_DIR)" ] && echo "OK: Xcode at $(XCODE_DEVELOPER_DIR)" || echo "MISSING: Xcode at $(XCODE_DEVELOPER_DIR)"
	@command -v xcodegen >/dev/null && echo "OK: xcodegen" || echo "MISSING: xcodegen (brew install xcodegen)"
	@echo "-- Android --"
	@command -v gradle >/dev/null && echo "OK: gradle" || echo "MISSING: gradle"
	@[ -d "$(ANDROID_NDK_HOME)" ] && echo "OK: NDK at $(ANDROID_NDK_HOME)" || echo "MISSING: NDK at $(ANDROID_NDK_HOME)"
	@[ -x "$(ANDROID_HOME)/platform-tools/adb" ] && echo "OK: adb" || echo "MISSING: adb"
	@[ -x "$(ANDROID_HOME)/cmdline-tools/latest/bin/sdkmanager" ] && echo "OK: cmdline-tools" || echo "MISSING: Android cmdline-tools"
