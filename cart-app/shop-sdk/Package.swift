// swift-tools-version:6.0

//
//  Package.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import PackageDescription

// SwiftPM manifest for the shop-sdk library and its test target.
let package = Package(
    name: "shop-sdk",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ShopSDK", targets: ["ShopSDK"]),
    ],
    targets: [
        .target(
            name: "ShopSDK",
            path: "Sources/ShopSDK"
        ),
        .testTarget(
            name: "ShopSDKTests",
            dependencies: ["ShopSDK"]
        ),
    ]
)
