//
//  SortOption.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

public enum SortOption: String, Codable, CaseIterable, Sendable {
    case popularity
    case nameAscending
    case nameDescending
}
