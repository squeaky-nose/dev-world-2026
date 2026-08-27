//
//  ProductListViewModel.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Observation
import ShopSDK

/// View model for the Products tab: holds the current tag filter and sort choice, and
/// re-derives the displayed product list whenever either changes.
@MainActor
@Observable
final class ProductListViewModel {
    private let sdk: ShopSDK

    var products: [Product] = []
    var selectedTag: Tag?
    var selectedSort: SortOption = .popularity
    let availableTags: [Tag]
    let availableSortOptions: [SortOption]

    /// Creates the view model, loading available filter/sort choices and the initial product list.
    init(sdk: ShopSDK) {
        self.sdk = sdk
        self.availableTags = sdk.allTags()
        self.availableSortOptions = sdk.allSortOptions()
        reload()
    }

    /// Sets the active tag filter (`nil` for no filter) and reloads the product list.
    func selectTag(_ tag: Tag?) {
        selectedTag = tag
        reload()
    }

    /// Sets the active sort option and reloads the product list.
    func selectSort(_ sort: SortOption) {
        selectedSort = sort
        reload()
    }

    /// Re-fetches `products` from the SDK using the current tag filter and sort option.
    private func reload() {
        let tags = selectedTag.map { [$0] } ?? []
        products = sdk.products(matching: tags, sortedBy: selectedSort)
    }
}
