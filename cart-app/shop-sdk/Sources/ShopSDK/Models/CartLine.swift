//
//  CartLine.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

/// A single priced line in the cart: one product, its quantity, and the resulting subtotal/discount/total.
public struct CartLine: Codable, Sendable, Equatable {
    public let productId: String
    public let quantity: Int
    public let unitPrice: Decimal
    public let lineSubtotal: Decimal
    public let lineDiscount: Decimal
    public let lineTotal: Decimal

    /// Creates a cart line from already-computed pricing values.
    public init(
        productId: String,
        quantity: Int,
        unitPrice: Decimal,
        lineSubtotal: Decimal,
        lineDiscount: Decimal,
        lineTotal: Decimal
    ) {
        self.productId = productId
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.lineSubtotal = lineSubtotal
        self.lineDiscount = lineDiscount
        self.lineTotal = lineTotal
    }
}
