//
//  CartView.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import SwiftUI
import ShopSDK

/// Cart tab: line items, promo code entry, order summary, and checkout, or an order
/// confirmation screen once checkout succeeds.
struct CartView: View {
    @Bindable var viewModel: CartViewModel

    var body: some View {
        Group {
            if viewModel.orderPlaced {
                OrderConfirmationView(onContinueShopping: viewModel.continueShopping)
            } else {
                List {
                    if viewModel.totals.lines.isEmpty {
                        ContentUnavailableView("Your cart is empty", systemImage: "cart")
                    } else {
                        Section("Items") {
                            ForEach(viewModel.totals.lines, id: \.productId) { line in
                                CartLineRow(line: line, product: viewModel.product(for: line)) { newQuantity in
                                    viewModel.setQuantity(productId: line.productId, quantity: newQuantity)
                                } onRemove: {
                                    viewModel.remove(productId: line.productId)
                                }
                            }
                        }

                        Section("Promo code") {
                            HStack {
                                TextField("Enter code", text: $viewModel.promoCodeText)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                Button("Apply") { viewModel.applyPromoCode() }
                            }
                            if let code = viewModel.totals.promoCode {
                                Label("\"\(code)\" applied", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                            }
                        }

                        Section("Summary") {
                            SummaryRow(label: "Subtotal", value: viewModel.totals.bulkDiscountedSubtotal)
                            if viewModel.totals.promoDiscount > 0 {
                                SummaryRow(label: "Promo discount", value: -viewModel.totals.promoDiscount)
                            }
                            SummaryRow(label: "Shipping", value: viewModel.totals.shipping)
                            SummaryRow(label: "Total", value: viewModel.totals.grandTotal, emphasized: true)
                        }

                        Section {
                            Button {
                                Task { await viewModel.checkout() }
                            } label: {
                                HStack {
                                    Spacer()
                                    if viewModel.isCheckingOut {
                                        ProgressView()
                                    } else {
                                        Text("Checkout")
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isCheckingOut)

                            if let result = viewModel.checkoutResult {
                                Label(result.message, systemImage: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result.success ? .green : .red)
                            }
                        }
                    }
                }
                .onAppear { viewModel.refresh() }
            }
        }
        .navigationTitle("Cart")
    }
}

/// Success screen shown after a completed checkout, with a button to reset back to browsing.
private struct OrderConfirmationView: View {
    let onContinueShopping: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Order placed!")
                .font(.title2)
                .bold()

            Text("Thanks for your order. Your cart is ready for next time.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Continue Shopping", action: onContinueShopping)
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// One cart row: product name/price, a quantity stepper, and a swipe-to-remove action.
private struct CartLineRow: View {
    let line: CartLine
    let product: Product?
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product?.name ?? line.productId).font(.headline)
                Text(line.lineTotal, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if line.lineDiscount > 0 {
                    Text("Bulk discount applied").font(.caption).foregroundStyle(.green)
                }
            }
            Spacer()
            Stepper("Qty: \(line.quantity)", value: Binding(
                get: { line.quantity },
                set: { onQuantityChange($0) }
            ), in: 0...50)
            .labelsHidden()
            Text("\(line.quantity)")
                .frame(minWidth: 20)
        }
        .swipeActions {
            Button("Remove", role: .destructive, action: onRemove)
        }
    }
}

/// A label/value row in the order summary, optionally emphasized (e.g. for the grand total).
private struct SummaryRow: View {
    let label: String
    let value: Decimal
    var emphasized: Bool = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value, format: .currency(code: "USD"))
        }
        .font(emphasized ? .headline : .subheadline)
    }
}
