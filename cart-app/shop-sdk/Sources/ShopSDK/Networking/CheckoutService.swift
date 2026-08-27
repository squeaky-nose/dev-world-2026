//
//  CheckoutService.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Submits cart totals to the checkout endpoint over HTTP.
final class CheckoutService: Sendable {
    private let checkoutURL: URL

    /// Creates a service that POSTs checkout requests to `checkoutURL`.
    init(checkoutURL: URL) {
        self.checkoutURL = checkoutURL
    }

    /// POSTs the cart totals as JSON and maps the HTTP response into a `CheckoutResult`.
    /// Throws `ShopSDKError.networkError` on encode or transport failure.
    func checkout(totals: CartTotals) async throws -> CheckoutResult {
        var request = URLRequest(url: checkoutURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            request.httpBody = try encoder.encode(totals)
        } catch {
            throw ShopSDKError.networkError("Failed to encode cart: \(error.localizedDescription)")
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let success = (200..<300).contains(statusCode ?? 0)
            return CheckoutResult(
                success: success,
                httpStatusCode: statusCode,
                message: success ? "Order submitted successfully." : "Checkout failed with status \(statusCode.map(String.init) ?? "unknown")."
            )
        } catch {
            throw ShopSDKError.networkError(error.localizedDescription)
        }
    }

    /// Blocking wrapper around `checkout(totals:)` for non-async callers: spawns a `Task` and
    /// blocks the current thread on a semaphore until it completes.
    func checkoutSync(totals: CartTotals) -> CheckoutResult {
        let box = ResultBox()
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            defer { semaphore.signal() }
            do {
                box.result = try await checkout(totals: totals)
            } catch {
                box.result = CheckoutResult(success: false, httpStatusCode: nil, message: "\(error)")
            }
        }

        semaphore.wait()
        return box.result
    }

    /// Mutable box used to hand a result back out of the detached `Task` in `checkoutSync`.
    private final class ResultBox: @unchecked Sendable {
        var result = CheckoutResult(success: false, httpStatusCode: nil, message: "Checkout did not complete.")
    }
}
