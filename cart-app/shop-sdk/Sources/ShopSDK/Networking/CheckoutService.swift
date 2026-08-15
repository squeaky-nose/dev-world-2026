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

final class CheckoutService: Sendable {
    private let checkoutURL: URL

    init(checkoutURL: URL) {
        self.checkoutURL = checkoutURL
    }

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

    private final class ResultBox: @unchecked Sendable {
        var result = CheckoutResult(success: false, httpStatusCode: nil, message: "Checkout did not complete.")
    }
}
