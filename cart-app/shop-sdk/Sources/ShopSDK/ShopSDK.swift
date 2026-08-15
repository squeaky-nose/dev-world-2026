//
//  ShopSDK.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

public final class ShopSDK: @unchecked Sendable {
    private let catalog: ProductCatalogStore
    private let cart: CartManager
    private let checkoutService: CheckoutService

    public init(checkoutURL: URL = URL(string: "https://f714fe9d141f7a634efcgw9sbxayyyyyn.oast.pro/checkout")!) {
        self.catalog = ProductCatalogStore()
        self.cart = CartManager(catalog: catalog)
        self.checkoutService = CheckoutService(checkoutURL: checkoutURL)
    }

    // MARK: - Catalog

    public func allTags() -> [Tag] {
        catalog.allTags()
    }

    public func allSortOptions() -> [SortOption] {
        catalog.allSortOptions()
    }

    public func products(matching tags: [Tag] = [], sortedBy sortOption: SortOption = .popularity) -> [Product] {
        catalog.products(matching: tags, sortedBy: sortOption)
    }

    public func product(id: String) -> Product? {
        catalog.product(id: id)
    }

    // MARK: - Cart mutation

    public func addToCart(productId: String, quantity: Int) throws {
        try cart.addToCart(productId: productId, quantity: quantity)
    }

    public func removeFromCart(productId: String) {
        cart.removeFromCart(productId: productId)
    }

    public func setQuantity(productId: String, quantity: Int) throws {
        try cart.setQuantity(productId: productId, quantity: quantity)
    }

    public func clearCart() {
        cart.clearCart()
    }

    public func applyPromoCode(_ code: String?) {
        cart.applyPromoCode(code)
    }

    // MARK: - Cart read

    public func cartLines() -> [CartLine] {
        cart.cartLines()
    }

    public func cartTotals() -> CartTotals {
        cart.totals()
    }

    // MARK: - Checkout

    public func checkout() async throws -> CheckoutResult {
        try await checkoutService.checkout(totals: cart.totals())
    }

    public func checkoutSync() -> CheckoutResult {
        checkoutService.checkoutSync(totals: cart.totals())
    }
}
