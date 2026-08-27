//
//  PricingEngineTests.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Testing
@testable import ShopSDK

/// Builds a minimal throwaway product with a given price, for isolating pricing math from catalog data.
private func makeProduct(id: String = "widget", price: Decimal) -> Product {
    Product(
        id: id,
        name: id,
        description: "test",
        imageURL: "https://example.com/x.jpg",
        unitPrice: price,
        tags: [.vegetable],
        recipeIdeas: [],
        popularity: 0.5
    )
}

/// Unit tests for `PricingEngine.compute`, covering bulk discounts, promo codes, and shipping rules.
@Suite("PricingEngine")
struct PricingEngineTests {

    /// An empty item list should short-circuit to `.empty` rather than computing zeroed totals.
    @Test("Empty cart has zero totals and no shipping")
    func emptyCart() {
        let totals = PricingEngine.compute(items: [], promoCode: nil)
        #expect(totals == .empty)
        #expect(totals.grandTotal == 0)
        #expect(totals.shipping == 0)
    }

    /// Quantity exactly at the bulk-discount threshold should NOT qualify (threshold is exclusive).
    @Test("Quantity of 5 or fewer gets no bulk discount")
    func noBulkDiscountAtThreshold() {
        let product = makeProduct(price: 10)
        let totals = PricingEngine.compute(items: [(product, 5)], promoCode: nil)
        #expect(totals.lines[0].lineDiscount == 0)
        #expect(totals.lines[0].lineTotal == 50)
        #expect(totals.bulkDiscountedSubtotal == 50)
    }

    /// One unit past the threshold should trigger the 10% bulk discount on that line.
    @Test("Quantity over 5 gets a 10% bulk discount on that line")
    func bulkDiscountAboveThreshold() {
        let product = makeProduct(price: 10)
        let totals = PricingEngine.compute(items: [(product, 6)], promoCode: nil)
        #expect(totals.lines[0].lineSubtotal == 60)
        #expect(totals.lines[0].lineDiscount == 6)
        #expect(totals.lines[0].lineTotal == 54)
        #expect(totals.bulkDiscountedSubtotal == 54)
    }

    /// The promo discount applies to the post-bulk-discount subtotal, not the raw subtotal.
    @Test("Promo code devworld halves the bulk-discounted subtotal")
    func promoCodeAppliesFiftyPercentOff() {
        let product = makeProduct(price: 10)
        let totals = PricingEngine.compute(items: [(product, 6)], promoCode: "devworld")
        // bulkDiscountedSubtotal is 54; promo halves it.
        #expect(totals.promoCode == "devworld")
        #expect(totals.promoDiscount == 27)
        #expect(totals.merchandiseTotal == 27)
    }

    /// Mixed-case input with surrounding whitespace should still match the promo code.
    @Test("Promo code is case-insensitive and trims whitespace")
    func promoCodeNormalization() {
        let product = makeProduct(price: 10)
        let totals = PricingEngine.compute(items: [(product, 1)], promoCode: "  DevWorld  ")
        #expect(totals.promoCode == "devworld")
        #expect(totals.promoDiscount == 5)
    }

    /// A code that doesn't match the one recognized promo should be silently ignored, not an error.
    @Test("Unknown promo code is ignored")
    func unknownPromoCodeIgnored() {
        let product = makeProduct(price: 10)
        let totals = PricingEngine.compute(items: [(product, 1)], promoCode: "not-a-real-code")
        #expect(totals.promoCode == nil)
        #expect(totals.promoDiscount == 0)
        #expect(totals.merchandiseTotal == 10)
    }

    /// Merchandise total exactly at the free-shipping threshold should still be charged (threshold is exclusive).
    @Test("Shipping is $10 when merchandise total is $30 or less")
    func shippingChargedAtOrBelowThreshold() {
        let product = makeProduct(price: 10)
        let totals = PricingEngine.compute(items: [(product, 3)], promoCode: nil) // merchandiseTotal == 30
        #expect(totals.merchandiseTotal == 30)
        #expect(totals.shipping == 10)
        #expect(totals.grandTotal == 40)
    }

    /// One dollar past the free-shipping threshold should waive the shipping fee.
    @Test("Shipping is free when merchandise total exceeds $30")
    func freeShippingAboveThreshold() {
        let product = makeProduct(price: 10)
        let totals = PricingEngine.compute(items: [(product, 4)], promoCode: nil) // merchandiseTotal == 40 (qty<=5, no bulk discount)
        #expect(totals.merchandiseTotal == 40)
        #expect(totals.shipping == 0)
        #expect(totals.grandTotal == 40)
    }

    /// Verifies per-line discounting and cart-level summation both hold when lines are mixed
    /// (one over the bulk threshold, one under).
    @Test("Multiple lines sum correctly with mixed discounts")
    func multipleLines() {
        let bananas = makeProduct(id: "bananas", price: Decimal(string: "0.40")!)
        let avocado = makeProduct(id: "avocado", price: Decimal(string: "1.80")!)
        let totals = PricingEngine.compute(items: [(bananas, 6), (avocado, 2)], promoCode: nil)
        // bananas: 6 * 0.40 = 2.40, 10% off -> 2.16
        // avocado: 2 * 1.80 = 3.60, no discount
        #expect(totals.bulkDiscountedSubtotal == Decimal(string: "5.76")!)
        #expect(totals.shipping == 10)
        #expect(totals.grandTotal == Decimal(string: "15.76")!)
    }

    /// Same mixed-line scenario as `multipleLines`, but also stacking the promo discount on top.
    @Test("Multiple lines with promo code applied")
    func multipleLinesWithPromo() {
        let bananas = makeProduct(id: "bananas", price: Decimal(string: "0.40")!)
        let avocado = makeProduct(id: "avocado", price: Decimal(string: "1.80")!)
        let totals = PricingEngine.compute(items: [(bananas, 6), (avocado, 2)], promoCode: "devworld")
        #expect(totals.bulkDiscountedSubtotal == Decimal(string: "5.76")!)
        #expect(totals.promoDiscount == Decimal(string: "2.88")!)
        #expect(totals.merchandiseTotal == Decimal(string: "2.88")!)
        #expect(totals.shipping == 10)
        #expect(totals.grandTotal == Decimal(string: "12.88")!)
    }
}
