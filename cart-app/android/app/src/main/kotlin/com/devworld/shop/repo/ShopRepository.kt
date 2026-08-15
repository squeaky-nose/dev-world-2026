//
//  ShopRepository.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.repo

import com.devworld.shop.bridge.ShopSdkBridge
import com.devworld.shop.bridge.dto.CartTotals
import com.devworld.shop.bridge.dto.CheckoutResult
import com.devworld.shop.bridge.dto.ErrorEnvelope
import com.devworld.shop.bridge.dto.Product
import com.devworld.shop.bridge.dto.ShopSdkException
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class ShopRepository {
    private val json = Json { ignoreUnknownKeys = true }

    fun getTags(): List<String> = json.decodeFromString(ShopSdkBridge.nativeGetTags())

    fun getSortOptions(): List<String> = json.decodeFromString(ShopSdkBridge.nativeGetSortOptions())

    fun getProducts(tags: List<String>, sortOption: String = "popularity"): List<Product> {
        val tagsJson = json.encodeToString(tags)
        return json.decodeFromString(ShopSdkBridge.nativeGetProducts(tagsJson, sortOption))
    }

    fun getProduct(id: String): Product = decodeOrThrow(ShopSdkBridge.nativeGetProduct(id))

    fun addToCart(productId: String, quantity: Int): CartTotals =
        decodeOrThrow(ShopSdkBridge.nativeAddToCart(productId, quantity))

    fun setQuantity(productId: String, quantity: Int): CartTotals =
        decodeOrThrow(ShopSdkBridge.nativeSetQuantity(productId, quantity))

    fun removeFromCart(productId: String): CartTotals =
        decodeOrThrow(ShopSdkBridge.nativeRemoveFromCart(productId))

    fun clearCart(): CartTotals = decodeOrThrow(ShopSdkBridge.nativeClearCart())

    fun applyPromoCode(code: String?): CartTotals =
        decodeOrThrow(ShopSdkBridge.nativeApplyPromoCode(code ?: ""))

    fun getCartTotals(): CartTotals = decodeOrThrow(ShopSdkBridge.nativeGetCartTotals())

    fun checkout(): CheckoutResult = decodeOrThrow(ShopSdkBridge.nativeCheckout())

    private inline fun <reified T> decodeOrThrow(rawJson: String): T {
        return try {
            json.decodeFromString<T>(rawJson)
        } catch (decodeError: Exception) {
            val envelope = try {
                json.decodeFromString<ErrorEnvelope>(rawJson)
            } catch (_: Exception) {
                null
            }
            throw ShopSdkException(envelope?.error ?: "Malformed response from shop-sdk: $rawJson")
        }
    }
}
