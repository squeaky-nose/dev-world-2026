//
//  Models.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.bridge.dto

import kotlinx.serialization.Serializable

// Kotlin-side mirrors of the JSON shapes produced by ShopSDKAndroidBridge/Bridge.swift.
// Monetary fields are Double here (JSON has no decimal type) even though the Swift side
// uses Decimal internally; precision loss is not a practical concern at this scale.

/** A single catalog item as decoded from the native bridge. */
@Serializable
data class Product(
    val id: String,
    val name: String,
    val description: String,
    val imageURL: String,
    val unitPrice: Double,
    val tags: List<String>,
    val recipeIdeas: List<String>,
    val popularity: Double,
)

/** A single priced cart line as decoded from the native bridge. */
@Serializable
data class CartLine(
    val productId: String,
    val quantity: Int,
    val unitPrice: Double,
    val lineSubtotal: Double,
    val lineDiscount: Double,
    val lineTotal: Double,
)

/** Cart-level pricing summary as decoded from the native bridge. */
@Serializable
data class CartTotals(
    val lines: List<CartLine>,
    val bulkDiscountedSubtotal: Double,
    val promoCode: String? = null,
    val promoDiscount: Double,
    val merchandiseTotal: Double,
    val shipping: Double,
    val grandTotal: Double,
) {
    companion object {
        // Default UI state before the first native call resolves.
        val empty = CartTotals(
            lines = emptyList(),
            bulkDiscountedSubtotal = 0.0,
            promoCode = null,
            promoDiscount = 0.0,
            merchandiseTotal = 0.0,
            shipping = 0.0,
            grandTotal = 0.0,
        )
    }
}

/** Outcome of a checkout attempt as decoded from the native bridge. */
@Serializable
data class CheckoutResult(
    val success: Boolean,
    val httpStatusCode: Int? = null,
    val message: String,
)

/** JSON shape the native bridge returns instead of throwing across the JNI boundary. */
@Serializable
data class ErrorEnvelope(val error: String)

/** Thrown by ShopRepository when a native call returns an `ErrorEnvelope`. */
class ShopSdkException(message: String) : Exception(message)
