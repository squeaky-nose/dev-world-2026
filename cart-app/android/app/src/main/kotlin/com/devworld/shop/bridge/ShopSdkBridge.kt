//
//  ShopSdkBridge.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.bridge

/**
 * Thin JNI declarations for the native `libshopsdk.so` (built from shop-sdk-android-bridge's
 * Bridge.swift). Every call crosses the boundary as a JSON string in both directions; see
 * ShopRepository for the Kotlin-side decoding.
 */
object ShopSdkBridge {
    init {
        // Must load before any external fun below is called.
        System.loadLibrary("shopsdk")
    }

    /** Liveness check; native side always returns "pong". */
    external fun nativePing(): String
    /** JSON array of all product tags. */
    external fun nativeGetTags(): String
    /** JSON array of all sort options. */
    external fun nativeGetSortOptions(): String
    /** JSON array of products filtered by a JSON tag array and sorted by name. */
    external fun nativeGetProducts(tagsJson: String, sortOption: String): String
    /** JSON of a single product, or an error envelope if the id is unknown. */
    external fun nativeGetProduct(productId: String): String
    /** Adds a quantity to the cart; returns updated totals JSON or an error envelope. */
    external fun nativeAddToCart(productId: String, quantity: Int): String
    /** Overwrites a line's quantity; returns updated totals JSON or an error envelope. */
    external fun nativeSetQuantity(productId: String, quantity: Int): String
    /** Removes a line from the cart; returns updated totals JSON. */
    external fun nativeRemoveFromCart(productId: String): String
    /** Empties the cart; returns the zeroed totals JSON. */
    external fun nativeClearCart(): String
    /** Applies (or, for an empty string, clears) a promo code; returns updated totals JSON. */
    external fun nativeApplyPromoCode(code: String): String
    /** Current cart totals JSON, without mutating state. */
    external fun nativeGetCartTotals(): String
    /** Submits the cart for checkout (blocking); returns the result JSON. */
    external fun nativeCheckout(): String
}
