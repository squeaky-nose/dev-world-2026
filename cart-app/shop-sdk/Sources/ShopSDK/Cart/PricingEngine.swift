//
//  PricingEngine.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

/// Pure pricing calculator: turns cart items into priced lines and cart-level totals
/// (bulk discounts, promo code, shipping). Stateless — all inputs are passed to `compute`.
enum PricingEngine {
    /// Quantity strictly above which a single cart line qualifies for the bulk discount.
    static let bulkDiscountThreshold = 5
    /// Fractional discount applied to a line's subtotal once it passes `bulkDiscountThreshold`.
    static let bulkDiscountRate: Decimal = 0.10
    /// The only promo code the SDK recognizes (case-insensitive, whitespace-trimmed).
    static let promoCode = "devworld"
    /// Fractional discount applied to the bulk-discounted subtotal when the promo code matches.
    static let promoDiscountRate: Decimal = 0.50
    /// Flat shipping fee charged when the merchandise total is at or below `freeShippingThreshold`.
    static let shippingCost: Decimal = 10
    /// Merchandise total strictly above which shipping becomes free.
    static let freeShippingThreshold: Decimal = 30

    /// Computes full cart totals for a set of (product, quantity) items and an optional promo code.
    /// Returns `.empty` for an empty cart.
    static func compute(items: [(product: Product, quantity: Int)], promoCode: String?) -> CartTotals {
        guard !items.isEmpty else { return .empty }

        let lines: [CartLine] = items.map { item in
            let lineSubtotal = item.product.unitPrice * Decimal(item.quantity)
            let lineDiscount = item.quantity > bulkDiscountThreshold
                ? lineSubtotal * bulkDiscountRate
                : 0
            return CartLine(
                productId: item.product.id,
                quantity: item.quantity,
                unitPrice: item.product.unitPrice,
                lineSubtotal: lineSubtotal,
                lineDiscount: lineDiscount,
                lineTotal: lineSubtotal - lineDiscount
            )
        }

        let bulkDiscountedSubtotal = lines.reduce(Decimal(0)) { $0 + $1.lineTotal }

        // Normalize before comparing so the promo code is case- and whitespace-insensitive.
        let normalizedPromoCode = promoCode?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let appliedPromoCode = normalizedPromoCode == PricingEngine.promoCode ? PricingEngine.promoCode : nil
        let promoDiscount = appliedPromoCode != nil ? bulkDiscountedSubtotal * promoDiscountRate : 0

        let merchandiseTotal = bulkDiscountedSubtotal - promoDiscount
        let shipping = merchandiseTotal > freeShippingThreshold ? 0 : shippingCost
        let grandTotal = merchandiseTotal + shipping

        return CartTotals(
            lines: lines,
            bulkDiscountedSubtotal: bulkDiscountedSubtotal,
            promoCode: appliedPromoCode,
            promoDiscount: promoDiscount,
            merchandiseTotal: merchandiseTotal,
            shipping: shipping,
            grandTotal: grandTotal
        )
    }
}
