//
//  CartManagerTests.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Testing
@testable import ShopSDK

@Suite("CartManager")
struct CartManagerTests {

    @Test("Adding to cart accumulates quantity")
    func addAccumulates() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 2)
        try cart.addToCart(productId: "avocado", quantity: 3)
        let lines = cart.cartLines()
        #expect(lines.count == 1)
        #expect(lines[0].quantity == 5)
    }

    @Test("Adding an unknown product throws productNotFound")
    func addUnknownProduct() {
        let cart = CartManager(catalog: ProductCatalogStore())
        #expect(throws: ShopSDKError.productNotFound("does-not-exist")) {
            try cart.addToCart(productId: "does-not-exist", quantity: 1)
        }
    }

    @Test("Adding a non-positive quantity throws invalidQuantity")
    func addNonPositiveQuantity() {
        let cart = CartManager(catalog: ProductCatalogStore())
        #expect(throws: ShopSDKError.invalidQuantity) {
            try cart.addToCart(productId: "avocado", quantity: 0)
        }
    }

    @Test("setQuantity to zero removes the line")
    func setQuantityZeroRemoves() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 2)
        try cart.setQuantity(productId: "avocado", quantity: 0)
        #expect(cart.cartLines().isEmpty)
    }

    @Test("removeFromCart clears the line")
    func removeFromCart() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 2)
        cart.removeFromCart(productId: "avocado")
        #expect(cart.cartLines().isEmpty)
    }

    @Test("clearCart empties all lines")
    func clearCart() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 2)
        try cart.addToCart(productId: "bananas", quantity: 1)
        cart.clearCart()
        #expect(cart.cartLines().isEmpty)
    }

    @Test("totals reflect promo code applied to the cart")
    func totalsReflectPromo() throws {
        let cart = CartManager(catalog: ProductCatalogStore())
        try cart.addToCart(productId: "avocado", quantity: 1)
        cart.applyPromoCode("devworld")
        #expect(cart.totals().promoCode == "devworld")
    }
}

@Suite("ShopSDK facade")
struct ShopSDKFacadeTests {

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

    @Test("setQuantity on the facade updates an existing line")
    func facadeSetQuantity() throws {
        let sdk = ShopSDK()
        try sdk.addToCart(productId: "avocado", quantity: 1)
        try sdk.setQuantity(productId: "avocado", quantity: 4)
        #expect(sdk.cartLines().first?.quantity == 4)
    }
}
