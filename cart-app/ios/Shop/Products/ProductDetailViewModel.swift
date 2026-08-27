//
//  ProductDetailViewModel.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Observation
import ShopSDK

/// View model for a single product's detail screen: tracks the quantity picker and add-to-cart state.
@MainActor
@Observable
final class ProductDetailViewModel {
    private let sdk: ShopSDK
    let product: Product
    var quantity: Int = 1
    var didAddToCart = false

    /// Creates the view model for a specific product, defaulting quantity to 1.
    init(sdk: ShopSDK, product: Product) {
        self.sdk = sdk
        self.product = product
    }

    /// Adds the selected quantity of this product to the cart; silently ignores an invalid quantity.
    func addToCart() {
        try? sdk.addToCart(productId: product.id, quantity: quantity)
        didAddToCart = true
    }
}
