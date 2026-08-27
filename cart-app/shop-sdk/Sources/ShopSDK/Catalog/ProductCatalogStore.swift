//
//  ProductCatalogStore.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

/// Read-only, in-memory catalog of products, filterable by tag and sortable by `SortOption`.
final class ProductCatalogStore: Sendable {
    private let products: [Product]

    /// Creates a store over the given products, defaulting to the built-in seed catalog.
    init(products: [Product] = ProductCatalog.all) {
        self.products = products
    }

    /// All tags a caller can filter products by.
    func allTags() -> [Tag] {
        Tag.allCases
    }

    /// All sort options a caller can apply to a product list.
    func allSortOptions() -> [SortOption] {
        SortOption.allCases
    }

    /// Products that carry at least one of `tags` (or all products if `tags` is empty), sorted by `sortOption`.
    func products(matching tags: [Tag], sortedBy sortOption: SortOption) -> [Product] {
        let filtered: [Product]
        if tags.isEmpty {
            filtered = products
        } else {
            let tagSet = Set(tags)
            filtered = products.filter { !tagSet.isDisjoint(with: $0.tags) }
        }

        switch sortOption {
        case .popularity:
            return filtered.sorted { $0.popularity > $1.popularity }
        case .nameAscending:
            return filtered.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return filtered.sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        }
    }

    /// Looks up a single product by id, or `nil` if it doesn't exist.
    func product(id: String) -> Product? {
        products.first { $0.id == id }
    }
}
