//
//  CartManager.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

/// Thread-safe in-memory cart state: tracks quantities per product and the applied promo code,
/// and derives totals via `PricingEngine` on demand.
final class CartManager: @unchecked Sendable {
    private let lock = NSLock()
    private var quantitiesByProductId: [String: Int] = [:]
    // Preserves insertion order so cart lines display in the order items were added.
    private var orderedProductIds: [String] = []
    private var appliedPromoCode: String?
    private let catalog: ProductCatalogStore

    /// Creates a cart backed by the given catalog, used to validate product ids and look up prices.
    init(catalog: ProductCatalogStore) {
        self.catalog = catalog
    }

    /// Adds `quantity` to the existing quantity for a product; throws if the product is unknown
    /// or `quantity` is not positive.
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

    /// Overwrites the quantity for a product; a quantity of 0 removes the line. Throws if the
    /// product is unknown or `quantity` is negative.
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

    /// Removes a product's line from the cart entirely, if present.
    func removeFromCart(productId: String) {
        lock.lock()
        defer { lock.unlock() }
        setQuantityLocked(productId: productId, quantity: 0)
    }

    /// Removes every line from the cart.
    func clearCart() {
        lock.lock()
        defer { lock.unlock() }
        quantitiesByProductId.removeAll()
        orderedProductIds.removeAll()
    }

    /// Sets (or clears, when `nil`) the promo code applied to future totals calculations.
    func applyPromoCode(_ code: String?) {
        lock.lock()
        defer { lock.unlock() }
        appliedPromoCode = code
    }

    /// The cart's line items, derived from the current totals computation.
    func cartLines() -> [CartLine] {
        totals().lines
    }

    /// Computes current totals from a locked snapshot of cart state, dropping any product ids
    /// that no longer resolve in the catalog or have a zero quantity.
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

    /// Applies a quantity change assuming `lock` is already held; removes the line at 0,
    /// otherwise inserts/updates it while keeping `orderedProductIds` in sync.
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
