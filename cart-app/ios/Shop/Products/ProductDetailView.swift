//
//  ProductDetailView.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import SwiftUI
import ShopSDK

struct ProductDetailView: View {
    @Bindable var viewModel: ProductDetailViewModel
    let cartViewModel: CartViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: viewModel.product.imageURL)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipped()

                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.product.name)
                        .font(.title2)
                        .bold()

                    Text(viewModel.product.unitPrice, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(viewModel.product.description)
                        .font(.body)

                    if !viewModel.product.recipeIdeas.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recipe ideas").font(.headline)
                            ForEach(viewModel.product.recipeIdeas, id: \.self) { idea in
                                Label(idea, systemImage: "fork.knife")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.top, 8)
                    }

                    Stepper("Quantity: \(viewModel.quantity)", value: $viewModel.quantity, in: 1...50)
                        .padding(.top, 8)

                    Button {
                        viewModel.addToCart()
                        cartViewModel.orderPlaced = false
                        cartViewModel.refresh()
                    } label: {
                        Text(viewModel.didAddToCart ? "Added!" : "Add to Cart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .navigationTitle(viewModel.product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
