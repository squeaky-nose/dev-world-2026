//
//  CartManager.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

final class CartManager: @unchecked Sendable {
    private let lock = NSLock()
    private var quantitiesByProductId: [String: Int] = [:]
    private var orderedProductIds: [String] = []
    private var appliedPromoCode: String?
    private let catalog: ProductCatalogStore

    init(catalog: ProductCatalogStore) {
        self.catalog = catalog
    }

    func addToCart(productId: String, quantity: Int) throws {
        guard catalog.product(id: productId) != nil else {
            throw ShopSDKError.productNotFound(productId)
        }
        guard quantity > 0 else {
            throw ShopSDKError.invalidQuantity
        }
        lock.lock()
        defer { lock.unlock() }
        let newQuantity = (quantitiesByProductId[productId] ?? 0) + quantity
        setQuantityLocked(productId: productId, quantity: newQuantity)
    }

    func setQuantity(productId: String, quantity: Int) throws {
        guard catalog.product(id: productId) != nil else {
            throw ShopSDKError.productNotFound(productId)
        }
        guard quantity >= 0 else {
            throw ShopSDKError.invalidQuantity
        }
        lock.lock()
        defer { lock.unlock() }
        setQuantityLocked(productId: productId, quantity: quantity)
    }

    func removeFromCart(productId: String) {
        lock.lock()
        defer { lock.unlock() }
        setQuantityLocked(productId: productId, quantity: 0)
    }

    func clearCart() {
        lock.lock()
        defer { lock.unlock() }
        quantitiesByProductId.removeAll()
        orderedProductIds.removeAll()
    }

    func applyPromoCode(_ code: String?) {
        lock.lock()
        defer { lock.unlock() }
        appliedPromoCode = code
    }

    func cartLines() -> [CartLine] {
        totals().lines
    }

    func totals() -> CartTotals {
        lock.lock()
        let items: [(product: Product, quantity: Int)] = orderedProductIds.compactMap { productId in
            guard let quantity = quantitiesByProductId[productId], quantity > 0,
                  let product = catalog.product(id: productId) else { return nil }
            return (product, quantity)
        }
        let promoCode = appliedPromoCode
        lock.unlock()
        return PricingEngine.compute(items: items, promoCode: promoCode)
    }

    private func setQuantityLocked(productId: String, quantity: Int) {
        if quantity <= 0 {
            quantitiesByProductId.removeValue(forKey: productId)
            orderedProductIds.removeAll { $0 == productId }
        } else {
            if quantitiesByProductId[productId] == nil {
                orderedProductIds.append(productId)
            }
            quantitiesByProductId[productId] = quantity
        }
    }
}
