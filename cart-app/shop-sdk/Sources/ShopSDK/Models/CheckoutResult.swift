//
//  CheckoutResult.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// Outcome of submitting a cart for checkout.
public struct CheckoutResult: Codable, Sendable, Equatable {
    public let success: Bool
    public let httpStatusCode: Int?
    public let message: String

    /// Creates a checkout result from a service response.
    public init(success: Bool, httpStatusCode: Int?, message: String) {
        self.success = success
        self.httpStatusCode = httpStatusCode
        self.message = message
    }
}
