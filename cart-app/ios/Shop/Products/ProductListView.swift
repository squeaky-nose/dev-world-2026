//
//  ProductListView.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import SwiftUI
import ShopSDK

struct ProductListView: View {
    @Bindable var viewModel: ProductListViewModel
    let cartViewModel: CartViewModel

    var body: some View {
        List {
            ForEach(viewModel.products) { product in
                NavigationLink {
                    ProductDetailView(viewModel: ProductDetailViewModel(sdk: cartViewModel.sdk, product: product), cartViewModel: cartViewModel)
                } label: {
                    ProductRow(product: product)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Products")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                filterSortMenu
            }
        }
    }

    private var filterSortMenu: some View {
        Menu {
            Menu {
                Button {
                    viewModel.selectTag(nil)
                } label: {
                    menuLabel("All", isSelected: viewModel.selectedTag == nil)
                }
                .accessibilityIdentifier("filterOption_all")

                ForEach(viewModel.availableTags, id: \.self) { tag in
                    Button {
                        viewModel.selectTag(tag)
                    } label: {
                        menuLabel(tag.rawValue.capitalized, isSelected: viewModel.selectedTag == tag)
                    }
                    .accessibilityIdentifier("filterOption_\(tag.rawValue)")
                }
            } label: {
                Label("Filter: \(filterLabel)", systemImage: "line.3.horizontal.decrease")
            }
            .accessibilityIdentifier("filterMenu")

            Menu {
                ForEach(viewModel.availableSortOptions, id: \.self) { option in
                    Button {
                        viewModel.selectSort(option)
                    } label: {
                        menuLabel(option.displayLabel, isSelected: viewModel.selectedSort == option)
                    }
                    .accessibilityIdentifier("sortOption_\(option.rawValue)")
                }
            } label: {
                Label("Sort: \(viewModel.selectedSort.displayLabel)", systemImage: "arrow.up.arrow.down")
            }
            .accessibilityIdentifier("sortMenu")
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityIdentifier("filterSortMenuButton")
    }

    private var filterLabel: String {
        viewModel.selectedTag?.rawValue.capitalized ?? "All"
    }

    @ViewBuilder
    private func menuLabel(_ text: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(text, systemImage: "checkmark")
        } else {
            Text(text)
        }
    }
}

private extension SortOption {
    var displayLabel: String {
        switch self {
        case .popularity: return "Popularity"
        case .nameAscending: return "A–Z"
        case .nameDescending: return "Z–A"
        }
    }
}

private struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.imageURL)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name).font(.headline)
                Text(product.tags.map(\.rawValue.capitalized).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(product.unitPrice, format: .currency(code: "USD"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
