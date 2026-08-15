//
//  ProductListViewModel.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Observation
import ShopSDK

@MainActor
@Observable
final class ProductListViewModel {
    private let sdk: ShopSDK

    var products: [Product] = []
    var selectedTag: Tag?
    var selectedSort: SortOption = .popularity
    let availableTags: [Tag]
    let availableSortOptions: [SortOption]

    init(sdk: ShopSDK) {
        self.sdk = sdk
        self.availableTags = sdk.allTags()
        self.availableSortOptions = sdk.allSortOptions()
        reload()
    }

    func selectTag(_ tag: Tag?) {
        selectedTag = tag
        reload()
    }

    func selectSort(_ sort: SortOption) {
        selectedSort = sort
        reload()
    }

    private func reload() {
        let tags = selectedTag.map { [$0] } ?? []
        products = sdk.products(matching: tags, sortedBy: selectedSort)
    }
}
