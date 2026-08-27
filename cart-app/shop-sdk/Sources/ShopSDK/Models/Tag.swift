//
//  Tag.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// Category labels used to filter the product catalog.
public enum Tag: String, Codable, CaseIterable, Sendable {
    case fruit
    case vegetable
    case dairy
    case pantry
    case construction
}
