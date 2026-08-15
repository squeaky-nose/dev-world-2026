//
//  CartViewModel.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Observation
import ShopSDK

@MainActor
@Observable
final class CartViewModel {
    let sdk: ShopSDK

    var totals: CartTotals = .empty
    var promoCodeText: String = ""
    var isCheckingOut = false
    var checkoutResult: CheckoutResult?
    var orderPlaced = false

    init(sdk: ShopSDK) {
        self.sdk = sdk
    }

    func refresh() {
        totals = sdk.cartTotals()
    }

    func product(for line: CartLine) -> Product? {
        sdk.product(id: line.productId)
    }

    func setQuantity(productId: String, quantity: Int) {
        try? sdk.setQuantity(productId: productId, quantity: quantity)
        refresh()
    }

    func remove(productId: String) {
        sdk.removeFromCart(productId: productId)
        refresh()
    }

    func applyPromoCode() {
        sdk.applyPromoCode(promoCodeText.isEmpty ? nil : promoCodeText)
        refresh()
    }

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

    func continueShopping() {
        orderPlaced = false
        checkoutResult = nil
    }
}
