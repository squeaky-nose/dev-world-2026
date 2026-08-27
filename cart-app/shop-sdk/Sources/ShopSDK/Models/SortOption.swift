//
//  SortOption.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

/// Ways a product list can be ordered.
public enum SortOption: String, Codable, CaseIterable, Sendable {
    /// Most popular first (descending `Product.popularity`).
    case popularity
    /// Alphabetical, A to Z.
    case nameAscending
    /// Alphabetical, Z to A.
    case nameDescending
}
