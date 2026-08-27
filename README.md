# Beyond the Orchard: Swift outside of the Apple ecosystem

Demo code for the [/dev/world 2026](https://devworld.au/) talk **"Beyond the Orchard: Swift outside of the Apple ecosystem"**, presented by Sushant Verma.

Four small projects, each showing Swift running somewhere it doesn't usually live: on a microcontroller, inside a JVM process, and cross-compiled for Android.

## Projects

### [`hello-morse/`](hello-morse/) — Embedded Swift
Swift Embedded firmware for a Seeed XIAO ESP32-C6 that blinks the onboard LED in Morse code, spelling out `"Hello DevWorld 2026!"` forever. Built with ESP-IDF. Demonstrates the basics of Embedded Swift — no Foundation, no `os.Logger` (a hand-rolled replacement with the same signatures instead), C interop via a bridging header.

### [`matter-light/`](matter-light/) — Embedded Swift
Firmware for the same ESP32-C6 board, one step further: a Matter-commissionable smart light (BLE commissioning, on/off control) built against esp-matter/connectedhomeip, plus a small custom feature for remote logging over plain HTTP with cJSON.

### [`jvm-love/`](jvm-love/) — Swift inside the JVM
A command-line Scrabble word finder that builds the same self-balancing AVL trie twice — once in native Kotlin, once in native Swift — inside a single JVM process, calling the compiled Swift library via [swift-java](https://github.com/swiftlang/swift-java)'s `jextract` FFM mode (Java's Foreign Function & Memory API). Compares search speed and FFM-crossing overhead between the two, side by side.

### [`cart-app/`](cart-app/) — Swift SDK for Android
A demo grocery app built twice — SwiftUI for iOS, Kotlin/Compose for Android — sharing one Swift business-logic package (`shop-sdk`). The Android app doesn't reimplement the logic in Kotlin: it calls the actual compiled Swift code through JNI, cross-compiled to Android via the official Swift SDK for Android.

## More

Each project has its own README with prerequisites, build/run instructions, and architecture notes.
