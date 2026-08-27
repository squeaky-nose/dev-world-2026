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

/** Kotlin-facing wrapper over `ShopSdkBridge`'s raw JSON strings: encodes/decodes DTOs and
 * turns native error envelopes into thrown exceptions. */
class ShopRepository {
    private val json = Json { ignoreUnknownKeys = true }

    /** All product tags available for filtering. */
    fun getTags(): List<String> = json.decodeFromString(ShopSdkBridge.nativeGetTags())

    /** All sort options available for the product list. */
    fun getSortOptions(): List<String> = json.decodeFromString(ShopSdkBridge.nativeGetSortOptions())

    /** Products matching every tag in `tags` (or all products if empty), sorted by `sortOption`. */
    fun getProducts(tags: List<String>, sortOption: String = "popularity"): List<Product> {
        val tagsJson = json.encodeToString(tags)
        return json.decodeFromString(ShopSdkBridge.nativeGetProducts(tagsJson, sortOption))
    }

    /** Looks up a single product by id; throws `ShopSdkException` if it doesn't exist. */
    fun getProduct(id: String): Product = decodeOrThrow(ShopSdkBridge.nativeGetProduct(id))

    /** Adds a quantity to the cart and returns updated totals; throws on an invalid product/quantity. */
    fun addToCart(productId: String, quantity: Int): CartTotals =
        decodeOrThrow(ShopSdkBridge.nativeAddToCart(productId, quantity))

    /** Overwrites a line's quantity and returns updated totals; throws on an invalid product/quantity. */
    fun setQuantity(productId: String, quantity: Int): CartTotals =
        decodeOrThrow(ShopSdkBridge.nativeSetQuantity(productId, quantity))

    /** Removes a line from the cart and returns updated totals. */
    fun removeFromCart(productId: String): CartTotals =
        decodeOrThrow(ShopSdkBridge.nativeRemoveFromCart(productId))

    /** Empties the cart and returns the zeroed totals. */
    fun clearCart(): CartTotals = decodeOrThrow(ShopSdkBridge.nativeClearCart())

    /** Applies (or, when `null`, clears) a promo code and returns updated totals. */
    fun applyPromoCode(code: String?): CartTotals =
        decodeOrThrow(ShopSdkBridge.nativeApplyPromoCode(code ?: ""))

    /** Current cart totals, without mutating state. */
    fun getCartTotals(): CartTotals = decodeOrThrow(ShopSdkBridge.nativeGetCartTotals())

    /** Submits the cart for checkout (blocking on the native side). */
    fun checkout(): CheckoutResult = decodeOrThrow(ShopSdkBridge.nativeCheckout())

    /**
     * Decodes `rawJson` as [T]; if that fails, retries as an `ErrorEnvelope` and throws
     * `ShopSdkException` with its message (or a generic message if even that decode fails).
     */
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
