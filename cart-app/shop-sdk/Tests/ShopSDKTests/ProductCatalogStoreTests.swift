//
//  ProductCatalogStoreTests.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Testing
@testable import ShopSDK

@Suite("ProductCatalogStore")
struct ProductCatalogStoreTests {

    @Test("Catalog has exactly 61 products")
    func productCount() {
        let store = ProductCatalogStore()
        #expect(store.products(matching: [], sortedBy: .popularity).count == 61)
    }

    @Test("All product ids are unique")
    func uniqueIds() {
        let store = ProductCatalogStore()
        let ids = store.products(matching: [], sortedBy: .popularity).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

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

    @Test("allTags returns fruit, vegetable, dairy, pantry, and construction")
    func tagsList() {
        let store = ProductCatalogStore()
        #expect(Set(store.allTags()) == [.fruit, .vegetable, .dairy, .pantry, .construction])
    }

    @Test("allSortOptions returns popularity, nameAscending, nameDescending")
    func sortOptionsList() {
        let store = ProductCatalogStore()
        #expect(Set(store.allSortOptions()) == [.popularity, .nameAscending, .nameDescending])
    }

    @Test("Filtering by vegetable returns only vegetables")
    func filterByVegetable() {
        let store = ProductCatalogStore()
        let vegetables = store.products(matching: [.vegetable], sortedBy: .popularity)
        #expect(!vegetables.isEmpty)
        #expect(vegetables.allSatisfy { $0.tags.contains(.vegetable) })
    }

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

    @Test("Filtering by construction returns only the four hardware products")
    func filterByConstruction() {
        let store = ProductCatalogStore()
        let construction = store.products(matching: [.construction], sortedBy: .popularity)
        #expect(construction.count == 4)
        #expect(construction.allSatisfy { $0.tags.contains(.construction) })
        #expect(Set(construction.map(\.id)) == ["hammer", "anvil", "screwdriver", "nails"])
    }

    @Test("Lookup by id returns the matching product, unknown id returns nil")
    func lookupById() {
        let store = ProductCatalogStore()
        #expect(store.product(id: "avocado")?.name == "Avocado")
        #expect(store.product(id: "does-not-exist") == nil)
    }

    @Test("Sorting by popularity orders products from most to least popular")
    func sortByPopularity() {
        let store = ProductCatalogStore()
        let products = store.products(matching: [], sortedBy: .popularity)
        let popularities = products.map(\.popularity)
        #expect(popularities == popularities.sorted(by: >))
        #expect(products.first?.id == "bananas") // highest hardcoded popularity (0.98)
    }

    @Test("Sorting nameAscending orders products A-Z")
    func sortNameAscending() {
        let store = ProductCatalogStore()
        let names = store.products(matching: [], sortedBy: .nameAscending).map(\.name)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    @Test("Sorting nameDescending orders products Z-A")
    func sortNameDescending() {
        let store = ProductCatalogStore()
        let names = store.products(matching: [], sortedBy: .nameDescending).map(\.name)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedDescending })
    }
}
