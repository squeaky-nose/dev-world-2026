//
//  CartTotals.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

public struct CartTotals: Codable, Sendable, Equatable {
    public let lines: [CartLine]
    public let bulkDiscountedSubtotal: Decimal
    public let promoCode: String?
    public let promoDiscount: Decimal
    public let merchandiseTotal: Decimal
    public let shipping: Decimal
    public let grandTotal: Decimal

    public init(
        lines: [CartLine],
        bulkDiscountedSubtotal: Decimal,
        promoCode: String?,
        promoDiscount: Decimal,
        merchandiseTotal: Decimal,
        shipping: Decimal,
        grandTotal: Decimal
    ) {
        self.lines = lines
        self.bulkDiscountedSubtotal = bulkDiscountedSubtotal
        self.promoCode = promoCode
        self.promoDiscount = promoDiscount
        self.merchandiseTotal = merchandiseTotal
        self.shipping = shipping
        self.grandTotal = grandTotal
    }

    public static var empty: CartTotals {
        CartTotals(
            lines: [],
            bulkDiscountedSubtotal: 0,
            promoCode: nil,
            promoDiscount: 0,
            merchandiseTotal: 0,
            shipping: 0,
            grandTotal: 0
        )
    }
}
