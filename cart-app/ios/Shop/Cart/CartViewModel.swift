//
//  CartViewModel.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Observation
import ShopSDK

/// View model for the Cart tab: mirrors SDK cart/totals state for SwiftUI and drives checkout.
@MainActor
@Observable
final class CartViewModel {
    let sdk: ShopSDK

    var totals: CartTotals = .empty
    var promoCodeText: String = ""
    var isCheckingOut = false
    var checkoutResult: CheckoutResult?
    var orderPlaced = false

    /// Creates the view model against a shared SDK instance; starts with empty totals until `refresh()`.
    init(sdk: ShopSDK) {
        self.sdk = sdk
    }

    /// Re-pulls `totals` from the SDK; call after any mutation so the view reflects current state.
    func refresh() {
        totals = sdk.cartTotals()
    }

    /// Looks up the full product for a cart line, for displaying name/image/price.
    func product(for line: CartLine) -> Product? {
        sdk.product(id: line.productId)
    }

    /// Updates a line's quantity and refreshes totals; silently ignores an invalid quantity.
    func setQuantity(productId: String, quantity: Int) {
        try? sdk.setQuantity(productId: productId, quantity: quantity)
        refresh()
    }

    /// Removes a line from the cart and refreshes totals.
    func remove(productId: String) {
        sdk.removeFromCart(productId: productId)
        refresh()
    }

    /// Applies the current `promoCodeText` (or clears it if empty) and refreshes totals.
    func applyPromoCode() {
        sdk.applyPromoCode(promoCodeText.isEmpty ? nil : promoCodeText)
        refresh()
    }

    /// Submits the cart for checkout, tracking in-flight/result state; on success, clears the
    /// cart and promo code so a new order can start fresh.
    func checkout() async {
        isCheckingOut = true
        checkoutResult = nil
        defer { isCheckingOut = false }
        do {
            let result = try await sdk.checkout()
            checkoutResult = result
            if result.success {
                // Start a fresh cart so anything added afterwards doesn't land in the
                // order that was just placed.
                sdk.clearCart()
                promoCodeText = ""
                orderPlaced = true
            }
            refresh()
        } catch {
            checkoutResult = CheckoutResult(success: false, httpStatusCode: nil, message: "\(error)")
        }
    }

    /// Dismisses the order-placed confirmation, returning the user to normal cart browsing.
    func continueShopping() {
        orderPlaced = false
        checkoutResult = nil
    }
}
