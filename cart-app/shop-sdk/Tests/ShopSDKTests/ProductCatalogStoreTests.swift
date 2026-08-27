//
//  ProductCatalogStoreTests.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Testing
@testable import ShopSDK

/// Data-integrity and filtering/sorting tests for the built-in `ProductCatalog` seed data,
/// via `ProductCatalogStore`.
@Suite("ProductCatalogStore")
struct ProductCatalogStoreTests {

    /// Guards against accidental additions/removals to the seed catalog going unnoticed.
    @Test("Catalog has exactly 61 products")
    func productCount() {
        let store = ProductCatalogStore()
        #expect(store.products(matching: [], sortedBy: .popularity).count == 61)
    }

    /// No two seed products should share an id, since ids are used as cart/lookup keys.
    @Test("All product ids are unique")
    func uniqueIds() {
        let store = ProductCatalogStore()
        let ids = store.products(matching: [], sortedBy: .popularity).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    /// Sanity-checks every seed product's required fields (tag, description, image URL,
    /// popularity range) and that non-construction items have at least one recipe idea.
    @Test("Every product has exactly one tag, a non-empty description, image URL, and a popularity score in 0...1; food products also have at least one recipe idea")
    func productDataIntegrity() {
        let store = ProductCatalogStore()
        for product in store.products(matching: [], sortedBy: .popularity) {
            #expect(!product.tags.isEmpty)
            #expect(!product.description.isEmpty)
            #expect(product.imageURL.hasPrefix("https://"))
            if !product.tags.contains(.construction) {
                #expect(!product.recipeIdeas.isEmpty)
            }
            #expect(product.unitPrice > 0)
            #expect(product.popularity >= 0 && product.popularity <= 1)
        }
    }

    /// `allTags()` should expose every case of `Tag`, nothing more or less.
    @Test("allTags returns fruit, vegetable, dairy, pantry, and construction")
    func tagsList() {
        let store = ProductCatalogStore()
        #expect(Set(store.allTags()) == [.fruit, .vegetable, .dairy, .pantry, .construction])
    }

    /// `allSortOptions()` should expose every case of `SortOption`, nothing more or less.
    @Test("allSortOptions returns popularity, nameAscending, nameDescending")
    func sortOptionsList() {
        let store = ProductCatalogStore()
        #expect(Set(store.allSortOptions()) == [.popularity, .nameAscending, .nameDescending])
    }

    /// Single-tag filtering should exclude products lacking that tag.
    @Test("Filtering by vegetable returns only vegetables")
    func filterByVegetable() {
        let store = ProductCatalogStore()
        let vegetables = store.products(matching: [.vegetable], sortedBy: .popularity)
        #expect(!vegetables.isEmpty)
        #expect(vegetables.allSatisfy { $0.tags.contains(.vegetable) })
    }

    /// Confirms tag filtering is a true partition: since every product has exactly one tag,
    /// the per-tag counts should sum back to the full catalog size.
    @Test("Filtering by fruit returns only fruit, and every tag's counts add up to the full catalog")
    func filterByFruit() {
        let store = ProductCatalogStore()
        let fruit = store.products(matching: [.fruit], sortedBy: .popularity)
        let vegetables = store.products(matching: [.vegetable], sortedBy: .popularity)
        let dairy = store.products(matching: [.dairy], sortedBy: .popularity)
        let pantry = store.products(matching: [.pantry], sortedBy: .popularity)
        let construction = store.products(matching: [.construction], sortedBy: .popularity)
        #expect(fruit.allSatisfy { $0.tags.contains(.fruit) })
        #expect(fruit.count + vegetables.count + dairy.count + pantry.count + construction.count == 61)
    }

    /// Pins the exact seed counts for the dairy and pantry categories.
    @Test("Filtering by dairy and pantry returns only their respective products")
    func filterByDairyAndPantry() {
        let store = ProductCatalogStore()
        let dairy = store.products(matching: [.dairy], sortedBy: .popularity)
        let pantry = store.products(matching: [.pantry], sortedBy: .popularity)
        #expect(dairy.count == 9)
        #expect(dairy.allSatisfy { $0.tags.contains(.dairy) })
        #expect(pantry.count == 8)
        #expect(pantry.allSatisfy { $0.tags.contains(.pantry) })
    }

    /// Pins the exact 4 hardware items seeded under the (otherwise food-only) catalog.
    @Test("Filtering by construction returns only the four hardware products")
    func filterByConstruction() {
        let store = ProductCatalogStore()
        let construction = store.products(matching: [.construction], sortedBy: .popularity)
        #expect(construction.count == 4)
        #expect(construction.allSatisfy { $0.tags.contains(.construction) })
        #expect(Set(construction.map(\.id)) == ["hammer", "anvil", "screwdriver", "nails"])
    }

    /// A known id resolves to its product; an unknown id resolves to `nil` rather than throwing.
    @Test("Lookup by id returns the matching product, unknown id returns nil")
    func lookupById() {
        let store = ProductCatalogStore()
        #expect(store.product(id: "avocado")?.name == "Avocado")
        #expect(store.product(id: "does-not-exist") == nil)
    }

    /// Popularity sort should be strictly descending, with bananas (the highest hardcoded score) first.
    @Test("Sorting by popularity orders products from most to least popular")
    func sortByPopularity() {
        let store = ProductCatalogStore()
        let products = store.products(matching: [], sortedBy: .popularity)
        let popularities = products.map(\.popularity)
        #expect(popularities == popularities.sorted(by: >))
        #expect(products.first?.id == "bananas") // highest hardcoded popularity (0.98)
    }

    /// Ascending name sort should match locale-aware string comparison, not raw byte order.
    @Test("Sorting nameAscending orders products A-Z")
    func sortNameAscending() {
        let store = ProductCatalogStore()
        let names = store.products(matching: [], sortedBy: .nameAscending).map(\.name)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    /// Descending name sort should match locale-aware string comparison, reversed.
    @Test("Sorting nameDescending orders products Z-A")
    func sortNameDescending() {
        let store = ProductCatalogStore()
        let names = store.products(matching: [], sortedBy: .nameDescending).map(\.name)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedDescending })
    }
}
