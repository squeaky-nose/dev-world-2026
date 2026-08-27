//
//  ShopSDK.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

/// Top-level facade for the shop SDK: wires together the catalog, cart, and
/// checkout service so host apps only need a single entry point.
public final class ShopSDK: @unchecked Sendable {
    private let catalog: ProductCatalogStore
    private let cart: CartManager
    private let checkoutService: CheckoutService

    /// Creates a fresh SDK instance with an empty cart and a seeded catalog.
    public init(checkoutURL: URL = URL(string: "https://f714fe9d141f7a634efcgw9sbxayyyyyn.oast.pro/checkout")!) {
        self.catalog = ProductCatalogStore()
        self.cart = CartManager(catalog: catalog)
        self.checkoutService = CheckoutService(checkoutURL: checkoutURL)
    }

    // MARK: - Catalog

    /// All tags usable as product filters, in catalog order.
    public func allTags() -> [Tag] {
        catalog.allTags()
    }

    /// All sort options offered for the product list.
    public func allSortOptions() -> [SortOption] {
        catalog.allSortOptions()
    }

    /// Products matching every tag in `tags` (or all products if empty), sorted by `sortOption`.
    public func products(matching tags: [Tag] = [], sortedBy sortOption: SortOption = .popularity) -> [Product] {
        catalog.products(matching: tags, sortedBy: sortOption)
    }

    /// Looks up a single product by id, or `nil` if it doesn't exist in the catalog.
    public func product(id: String) -> Product? {
        catalog.product(id: id)
    }

    // MARK: - Cart mutation

    /// Adds `quantity` of a product to the cart; throws if the product is unknown or quantity is invalid.
    public func addToCart(productId: String, quantity: Int) throws {
        try cart.addToCart(productId: productId, quantity: quantity)
    }

    /// Removes a product's line from the cart entirely, if present.
    public func removeFromCart(productId: String) {
        cart.removeFromCart(productId: productId)
    }

    /// Overwrites the quantity for an existing cart line; throws on an invalid quantity.
    public func setQuantity(productId: String, quantity: Int) throws {
        try cart.setQuantity(productId: productId, quantity: quantity)
    }

    /// Removes every line from the cart.
    public func clearCart() {
        cart.clearCart()
    }

    /// Applies (or clears, when `nil`) a promo code to the cart's pricing.
    public func applyPromoCode(_ code: String?) {
        cart.applyPromoCode(code)
    }

    // MARK: - Cart read

    /// The current cart contents as line items.
    public func cartLines() -> [CartLine] {
        cart.cartLines()
    }

    /// The current cart's computed totals (subtotal, discounts, tax, grand total).
    public func cartTotals() -> CartTotals {
        cart.totals()
    }

    // MARK: - Checkout

    /// Submits the current cart for checkout over the network.
    public func checkout() async throws -> CheckoutResult {
        try await checkoutService.checkout(totals: cart.totals())
    }

    /// Blocking/synchronous variant of `checkout()`, for callers that can't use async/await.
    public func checkoutSync() -> CheckoutResult {
        checkoutService.checkoutSync(totals: cart.totals())
    }
}
