#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_SDK_ID="swift-6.3.3-RELEASE_android"
SWIFT_SDK_BUNDLE="$HOME/Library/org.swift.swiftpm/swift-sdks/${SWIFT_SDK_ID}.artifactbundle"
RUNTIME_DIR="${SWIFT_SDK_BUNDLE}/swift-android/swift-resources/usr/lib/swift-aarch64/android"
JNI_LIBS_DIR="${REPO_ROOT}/android/app/src/main/jniLibs/arm64-v8a"

export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk/27.3.13750724}"

echo "==> Building shop-sdk Android bridge (aarch64-unknown-linux-android28)"
cd "${REPO_ROOT}/shop-sdk-android-bridge"
swift build --product shopsdk --swift-sdk aarch64-unknown-linux-android28 -c release

SO_PATH=$(find .build/aarch64-unknown-linux-android28/release -maxdepth 1 -name "libshopsdk.so")
if [[ -z "${SO_PATH}" ]]; then
    echo "error: libshopsdk.so not found after build" >&2
    exit 1
fi

echo "==> Packaging into ${JNI_LIBS_DIR}"
mkdir -p "${JNI_LIBS_DIR}"
rm -f "${JNI_LIBS_DIR}"/*.so
cp "${SO_PATH}" "${JNI_LIBS_DIR}/"
cp "${RUNTIME_DIR}"/*.so "${JNI_LIBS_DIR}/"
cp "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" "${JNI_LIBS_DIR}/"

# The Testing/XCTest runtime libs are dev-only and not linked by our .so; skip them to save space.
rm -f "${JNI_LIBS_DIR}/libTesting.so" "${JNI_LIBS_DIR}/libXCTest.so" "${JNI_LIBS_DIR}/lib_TestingInterop.so" "${JNI_LIBS_DIR}/lib_Testing_Foundation.so"

echo "==> Done. Contents of ${JNI_LIBS_DIR}:"
ls -la "${JNI_LIBS_DIR}"
