// swift-tools-version: 6.0

//
//  Package.swift
//  JvmLoveTrie
//
//  Created by Sushant Verma on 27/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "JvmLoveTrie",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "JvmLoveTrie",
            type: .dynamic,
            targets: ["JvmLoveTrie"]
        )
    ],
    dependencies: [
        // Points at the vendored, pinned checkout `make setup` clones -- see
        // ../../vendor/swift-java and the root README's "Versions" table for
        // the exact commit this is pinned to. Using a local path (rather than
        // a remote git pin) guarantees this Swift target and the Gradle side's
        // composite-build dependency on SwiftKitCore/SwiftKitFFM always come
        // from the identical commit.
        .package(name: "swift-java", path: "../../vendor/swift-java")
    ],
    targets: [
        .target(
            name: "JvmLoveTrie",
            dependencies: [
                .product(name: "SwiftJava", package: "swift-java"),
                .product(name: "SwiftRuntimeFunctions", package: "swift-java"),
            ],
            exclude: [
                "swift-java.config"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            plugins: [
                .plugin(name: "JExtractSwiftPlugin", package: "swift-java")
            ]
        )
    ]
)
