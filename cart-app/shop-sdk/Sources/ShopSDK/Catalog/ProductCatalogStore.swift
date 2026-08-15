//
//  ProductCatalogStore.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

final class ProductCatalogStore: Sendable {
    private let products: [Product]

    init(products: [Product] = ProductCatalog.all) {
        self.products = products
    }

    func allTags() -> [Tag] {
        Tag.allCases
    }

    func allSortOptions() -> [SortOption] {
        SortOption.allCases
    }

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

    func product(id: String) -> Product? {
        products.first { $0.id == id }
    }
}
