//
//  ProductDetailViewModel.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
import Observation
import ShopSDK

@MainActor
@Observable
final class ProductDetailViewModel {
    private let sdk: ShopSDK
    let product: Product
    var quantity: Int = 1
    var didAddToCart = false

    init(sdk: ShopSDK, product: Product) {
        self.sdk = sdk
        self.product = product
    }

    func addToCart() {
        try? sdk.addToCart(productId: product.id, quantity: quantity)
        didAddToCart = true
    }
}
