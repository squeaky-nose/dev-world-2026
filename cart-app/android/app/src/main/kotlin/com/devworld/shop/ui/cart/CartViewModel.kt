//
//  CartViewModel.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.ui.cart

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devworld.shop.bridge.dto.CartTotals
import com.devworld.shop.bridge.dto.CheckoutResult
import com.devworld.shop.bridge.dto.Product
import com.devworld.shop.repo.ShopRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** View model for the Cart screen: mirrors repository cart/totals state as flows and drives checkout. */
class CartViewModel(private val repository: ShopRepository) : ViewModel() {
    private val _totals = MutableStateFlow(CartTotals.empty)
    val totals: StateFlow<CartTotals> = _totals.asStateFlow()

    // Cached so cart rows can show product name/image without a native round-trip per line.
    private val _productsById = MutableStateFlow<Map<String, Product>>(emptyMap())
    val productsById: StateFlow<Map<String, Product>> = _productsById.asStateFlow()

    private val _promoCodeText = MutableStateFlow("")
    val promoCodeText: StateFlow<String> = _promoCodeText.asStateFlow()

    private val _isCheckingOut = MutableStateFlow(false)
    val isCheckingOut: StateFlow<Boolean> = _isCheckingOut.asStateFlow()

    private val _checkoutResult = MutableStateFlow<CheckoutResult?>(null)
    val checkoutResult: StateFlow<CheckoutResult?> = _checkoutResult.asStateFlow()

    private val _orderPlaced = MutableStateFlow(false)
    val orderPlaced: StateFlow<Boolean> = _orderPlaced.asStateFlow()

    init {
        viewModelScope.launch(Dispatchers.Default) {
            _productsById.value = repository.getProducts(emptyList()).associateBy { it.id }
        }
        refresh()
    }

    /** Re-pulls `totals` from the repository; call after any mutation made outside this view model. */
    fun refresh() {
        viewModelScope.launch(Dispatchers.Default) {
            _totals.value = repository.getCartTotals()
        }
    }

    /** Adds a quantity to the cart and updates `totals` on success; `onDone` runs regardless of outcome. */
    fun addToCart(productId: String, quantity: Int, onDone: () -> Unit = {}) {
        _orderPlaced.value = false // Clear a stale confirmation screen from a prior order.
        viewModelScope.launch(Dispatchers.Default) {
            runCatching { repository.addToCart(productId, quantity) }
                .onSuccess { _totals.value = it }
            onDone()
        }
    }

    /** Overwrites a line's quantity and updates `totals` on success. */
    fun setQuantity(productId: String, quantity: Int) {
        viewModelScope.launch(Dispatchers.Default) {
            runCatching { repository.setQuantity(productId, quantity) }
                .onSuccess { _totals.value = it }
        }
    }

    /** Removes a line from the cart and updates `totals`. */
    fun remove(productId: String) {
        viewModelScope.launch(Dispatchers.Default) {
            _totals.value = repository.removeFromCart(productId)
        }
    }

    /** Updates the in-progress promo code text field (not yet applied). */
    fun updatePromoCodeText(text: String) {
        _promoCodeText.value = text
    }

    /** Applies the current promo code text (blank clears it) and updates `totals`. */
    fun applyPromoCode() {
        viewModelScope.launch(Dispatchers.Default) {
            _totals.value = repository.applyPromoCode(_promoCodeText.value.ifBlank { null })
        }
    }

    /** Submits the cart for checkout, tracking in-flight/result state; on success, clears the
     * cart and promo code so a new order can start fresh. */
    fun checkout() {
        viewModelScope.launch(Dispatchers.Default) {
            _isCheckingOut.value = true
            _checkoutResult.value = null
            val result = runCatching { repository.checkout() }
                .getOrElse { CheckoutResult(success = false, httpStatusCode = null, message = it.message ?: "Unknown error") }
            _checkoutResult.value = result
            if (result.success) {
                // Start a fresh cart so anything added afterwards doesn't land in the
                // order that was just placed.
                _totals.value = repository.clearCart()
                _promoCodeText.value = ""
                _orderPlaced.value = true
            }
            _isCheckingOut.value = false
        }
    }

    /** Dismisses the order-placed confirmation, returning the user to normal cart browsing. */
    fun continueShopping() {
        _orderPlaced.value = false
        _checkoutResult.value = null
    }
}
