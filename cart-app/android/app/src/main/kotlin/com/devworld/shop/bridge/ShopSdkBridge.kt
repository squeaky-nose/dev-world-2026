//
//  ShopSdkBridge.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.bridge

object ShopSdkBridge {
    init {
        System.loadLibrary("shopsdk")
    }

    external fun nativePing(): String
    external fun nativeGetTags(): String
    external fun nativeGetSortOptions(): String
    external fun nativeGetProducts(tagsJson: String, sortOption: String): String
    external fun nativeGetProduct(productId: String): String
    external fun nativeAddToCart(productId: String, quantity: Int): String
    external fun nativeSetQuantity(productId: String, quantity: Int): String
    external fun nativeRemoveFromCart(productId: String): String
    external fun nativeClearCart(): String
    external fun nativeApplyPromoCode(code: String): String
    external fun nativeGetCartTotals(): String
    external fun nativeCheckout(): String
}
