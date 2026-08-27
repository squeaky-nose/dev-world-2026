//
//  ShopSDKError.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// Errors surfaced by cart and checkout operations.
public enum ShopSDKError: Error, Codable, Sendable, Equatable {
    /// No catalog product matches the given product id.
    case productNotFound(String)
    /// The requested quantity is out of the allowed range for the operation.
    case invalidQuantity
    /// The checkout request failed at the network/transport layer, with a description.
    case networkError(String)
}
