//
//  CheckoutResult.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

public struct CheckoutResult: Codable, Sendable, Equatable {
    public let success: Bool
    public let httpStatusCode: Int?
    public let message: String

    public init(success: Bool, httpStatusCode: Int?, message: String) {
        self.success = success
        self.httpStatusCode = httpStatusCode
        self.message = message
    }
}
