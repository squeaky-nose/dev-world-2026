//
//  ShopApp.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import SwiftUI
import ShopSDK

/// App entry point: owns the single SDK instance for the process and configures URL caching.
@main
struct ShopApp: App {
    private let sdk = ShopSDK()

    /// Configures a larger `URLCache` before any view loads product images.
    init() {
        // AsyncImage loads product images through URLSession.shared, which reads/writes
        // through URLCache.shared. The default shared cache is small (a few MB), so on a
        // catalog of 50+ images most of them fall out and get re-fetched from the network
        // on every launch. Wikimedia's images don't send Cache-Control/Expires, but they do
        // send Last-Modified/ETag, so URLCache's heuristic freshness + revalidation still
        // lets a larger disk cache avoid most re-downloads.
        URLCache.shared = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 250 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            AppRoot(sdk: sdk)
        }
    }
}
