//
//  PricingEngine.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

enum PricingEngine {
    static let bulkDiscountThreshold = 5
    static let bulkDiscountRate: Decimal = 0.10
    static let promoCode = "devworld"
    static let promoDiscountRate: Decimal = 0.50
    static let shippingCost: Decimal = 10
    static let freeShippingThreshold: Decimal = 30

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
