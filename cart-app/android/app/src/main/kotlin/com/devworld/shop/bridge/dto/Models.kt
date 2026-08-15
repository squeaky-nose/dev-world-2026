//
//  Models.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.bridge.dto

import kotlinx.serialization.Serializable

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

@Serializable
data class CartLine(
    val productId: String,
    val quantity: Int,
    val unitPrice: Double,
    val lineSubtotal: Double,
    val lineDiscount: Double,
    val lineTotal: Double,
)

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

@Serializable
data class CheckoutResult(
    val success: Boolean,
    val httpStatusCode: Int? = null,
    val message: String,
)

@Serializable
data class ErrorEnvelope(val error: String)

class ShopSdkException(message: String) : Exception(message)
