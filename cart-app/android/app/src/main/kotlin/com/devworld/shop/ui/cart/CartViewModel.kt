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

class CartViewModel(private val repository: ShopRepository) : ViewModel() {
    private val _totals = MutableStateFlow(CartTotals.empty)
    val totals: StateFlow<CartTotals> = _totals.asStateFlow()

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

    fun refresh() {
        viewModelScope.launch(Dispatchers.Default) {
            _totals.value = repository.getCartTotals()
        }
    }

    fun addToCart(productId: String, quantity: Int, onDone: () -> Unit = {}) {
        _orderPlaced.value = false
        viewModelScope.launch(Dispatchers.Default) {
            runCatching { repository.addToCart(productId, quantity) }
                .onSuccess { _totals.value = it }
            onDone()
        }
    }

    fun setQuantity(productId: String, quantity: Int) {
        viewModelScope.launch(Dispatchers.Default) {
            runCatching { repository.setQuantity(productId, quantity) }
                .onSuccess { _totals.value = it }
        }
    }

    fun remove(productId: String) {
        viewModelScope.launch(Dispatchers.Default) {
            _totals.value = repository.removeFromCart(productId)
        }
    }

    fun updatePromoCodeText(text: String) {
        _promoCodeText.value = text
    }

    fun applyPromoCode() {
        viewModelScope.launch(Dispatchers.Default) {
            _totals.value = repository.applyPromoCode(_promoCodeText.value.ifBlank { null })
        }
    }

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

    fun continueShopping() {
        _orderPlaced.value = false
        _checkoutResult.value = null
    }
}
