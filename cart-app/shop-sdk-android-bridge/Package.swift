// swift-tools-version:6.0

//
//  Package.swift
//  shop-sdk-android-bridge
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import PackageDescription

let package = Package(
    name: "shop-sdk-android-bridge",
    products: [
        .library(name: "shopsdk", type: .dynamic, targets: ["ShopSDKAndroidBridge"]),
    ],
    dependencies: [
        .package(path: "../shop-sdk"),
    ],
    targets: [
        .systemLibrary(
            name: "CJNI",
            path: "Sources/CJNI"
        ),
        .target(
            name: "ShopSDKAndroidBridge",
            dependencies: [
                .product(name: "ShopSDK", package: "shop-sdk"),
                "CJNI",
            ],
            path: "Sources/ShopSDKAndroidBridge"
        ),
    ]
)
