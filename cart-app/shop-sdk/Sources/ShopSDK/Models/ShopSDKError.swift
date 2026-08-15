//
//  ShopSDKError.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

public enum ShopSDKError: Error, Codable, Sendable, Equatable {
    case productNotFound(String)
    case invalidQuantity
    case networkError(String)
}
