//
//  AppRoot.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import SwiftUI
import ShopSDK

struct AppRoot: View {
    let sdk: ShopSDK
    @State private var cartViewModel: CartViewModel
    @State private var productListViewModel: ProductListViewModel

    init(sdk: ShopSDK) {
        self.sdk = sdk
        _cartViewModel = State(initialValue: CartViewModel(sdk: sdk))
        _productListViewModel = State(initialValue: ProductListViewModel(sdk: sdk))
    }

    var body: some View {
        TabView {
            NavigationStack {
                ProductListView(viewModel: productListViewModel, cartViewModel: cartViewModel)
            }
            .tabItem { Label("Products", systemImage: "carrot") }

            NavigationStack {
                CartView(viewModel: cartViewModel)
            }
            .tabItem { Label("Cart", systemImage: "cart") }
            .badge(cartViewModel.totals.lines.count)
        }
        .onAppear { cartViewModel.refresh() }
    }
}
