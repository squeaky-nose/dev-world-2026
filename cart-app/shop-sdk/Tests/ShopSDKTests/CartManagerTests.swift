//
//  CartManagerTests.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Testing
@testable import ShopSDK

/// Unit tests for `CartManager`'s quantity bookkeeping and promo-code state.
@Suite("CartManager")
struct CartManagerTests {

    /// Adding the same product twice should sum quantities into a single line, not create duplicates.
    @Test("Adding to cart accumulates quantity")
    func addAccumulates() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 2)
        try cart.addToCart(productId: "avocado", quantity: 3)
        let lines = cart.cartLines()
        #expect(lines.count == 1)
        #expect(lines[0].quantity == 5)
    }

    /// Adding a product id the catalog doesn't recognize should fail with `productNotFound`.
    @Test("Adding an unknown product throws productNotFound")
    func addUnknownProduct() {
        let cart = CartManager(catalog: ProductCatalogStore())
        #expect(throws: ShopSDKError.productNotFound("does-not-exist")) {
            try cart.addToCart(productId: "does-not-exist", quantity: 1)
        }
    }

    /// A zero (non-positive) quantity on `addToCart` should be rejected rather than silently no-op.
    @Test("Adding a non-positive quantity throws invalidQuantity")
    func addNonPositiveQuantity() {
        let cart = CartManager(catalog: ProductCatalogStore())
        #expect(throws: ShopSDKError.invalidQuantity) {
            try cart.addToCart(productId: "avocado", quantity: 0)
        }
    }

    /// Setting a line's quantity to 0 should remove it from the cart entirely.
    @Test("setQuantity to zero removes the line")
    func setQuantityZeroRemoves() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 2)
        try cart.setQuantity(productId: "avocado", quantity: 0)
        #expect(cart.cartLines().isEmpty)
    }

    /// Explicitly removing a product should clear its line.
    @Test("removeFromCart clears the line")
    func removeFromCart() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 2)
        cart.removeFromCart(productId: "avocado")
        #expect(cart.cartLines().isEmpty)
    }

    /// Clearing the cart should drop every line regardless of how many were added.
    @Test("clearCart empties all lines")
    func clearCart() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 2)
        try cart.addToCart(productId: "bananas", quantity: 1)
        cart.clearCart()
        #expect(cart.cartLines().isEmpty)
    }

    /// A valid promo code should be reflected back on the computed totals.
    @Test("totals reflect promo code applied to the cart")
    func totalsReflectPromo() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 1)
        cart.applyPromoCode("devworld")
        #expect(cart.totals().promoCode == "devworld")
    }
}

/// End-to-end tests for the `ShopSDK` facade covering a full browse-to-checkout flow.
@Suite("ShopSDK facade")
struct ShopSDKFacadeTests {

    /// Exercises browsing/filtering the catalog, adding items, applying a promo, and
    /// verifying the resulting grand total (which bakes in the bulk-discount, promo, and
    /// shipping rules from `PricingEngine`).
    @Test("Full flow: browse, filter, add to cart, apply promo, compute totals")
    func fullFlow() throws {
        let sdk = ShopSDK()
        #expect(sdk.products().count == 61)
        #expect(sdk.products(matching: [.fruit]).allSatisfy { $0.tags.contains(.fruit) })

        try sdk.addToCart(productId: "bananas", quantity: 6)
        try sdk.addToCart(productId: "avocado", quantity: 2)
        sdk.applyPromoCode("devworld")

        let totals = sdk.cartTotals()
        #expect(totals.grandTotal == Decimal(string: "12.88")!)

        sdk.clearCart()
        #expect(sdk.cartTotals() == .empty)
    }

    /// `setQuantity` called through the facade should update the underlying cart line in place.
    @Test("setQuantity on the facade updates an existing line")
    func facadeSetQuantity() throws {
        let sdk = ShopSDK()
        try sdk.addToCart(productId: "avocado", quantity: 1)
        try sdk.setQuantity(productId: "avocado", quantity: 4)
        #expect(sdk.cartLines().first?.quantity == 4)
    }
}
