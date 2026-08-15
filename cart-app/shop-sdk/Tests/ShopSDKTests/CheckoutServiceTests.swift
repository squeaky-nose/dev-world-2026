//
//  CheckoutServiceTests.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Testing
@testable import ShopSDK

@Suite("CheckoutService")
struct CheckoutServiceTests {

    @Test("checkout() POSTs the cart JSON to the checkout endpoint and gets an HTTP response")
    func checkoutRoundTrips() async throws {
        let sdk = ShopSDK()
        try sdk.addToCart(productId: "avocado", quantity: 2)

        let result = try await sdk.checkout()
        // The checkout endpoint is a third-party test service; we only assert that the
        // POST round-tripped and produced an HTTP status, not a specific status code.
        #expect(result.httpStatusCode != nil)
    }
}
