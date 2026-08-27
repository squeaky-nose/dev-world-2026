//
//  Bridge.swift
//  shop-sdk-android-bridge
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import CJNI
import Foundation
import ShopSDK

// Single shared SDK instance backing every JNI call below — cart state persists across
// calls for the lifetime of the process, matching one Android process using one cart.
private let sdk = ShopSDK()

/// JSON shape returned to Kotlin when a native call fails, instead of throwing across the JNI boundary.
private struct ErrorEnvelope: Codable {
    let error: String
}

/// Encodes any `Encodable` value to a JSON string, falling back to an error payload if encoding fails.
private func encodeJSON<T: Encodable>(_ value: T) -> String {
    guard let data = try? JSONEncoder().encode(value), let string = String(data: data, encoding: .utf8) else {
        return "{\"error\":\"encoding failed\"}"
    }
    return string
}

/// Wraps a message in the `ErrorEnvelope` JSON shape the Kotlin side expects on failure.
private func errorJSON(_ message: String) -> String {
    encodeJSON(ErrorEnvelope(error: message))
}

/// Copies a JNI `jstring` into a native Swift `String`, releasing the JNI-owned buffer afterward.
/// Returns an empty string for a null `jstring`.
private func jstringToString(_ env: UnsafeMutablePointer<JNIEnv?>, _ str: jstring?) -> String {
    guard let str else { return "" }
    let functions = env.pointee!.pointee
    guard let cString = functions.GetStringUTFChars(env, str, nil) else { return "" }
    defer { functions.ReleaseStringUTFChars(env, str, cString) }
    return String(cString: cString)
}

/// Allocates a new JNI `jstring` from a Swift `String` via the JNI function table.
private func stringToJString(_ env: UnsafeMutablePointer<JNIEnv?>, _ string: String) -> jstring {
    let functions = env.pointee!.pointee
    return functions.NewStringUTF(env, string)!
}

// Every function below is exported under a `Java_<package>_<Class>_<method>` symbol name —
// the JNI naming convention the JVM uses to resolve `external fun native...` declarations
// in ShopSdkBridge.kt. All results cross the boundary as JSON strings.

/// Liveness check used by the Kotlin bridge to confirm the native library loaded correctly.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativePing")
public func nativePing(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, "pong")
}

/// Returns all available product tags as a JSON array.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetTags")
public func nativeGetTags(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, encodeJSON(sdk.allTags()))
}

/// Returns all available sort options as a JSON array.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetSortOptions")
public func nativeGetSortOptions(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, encodeJSON(sdk.allSortOptions()))
}

/// Returns products filtered by a JSON-encoded tag array and sorted by the named sort option,
/// as a JSON array. Falls back to no tag filter / popularity sort on malformed input.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetProducts")
public func nativeGetProducts(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, tagsJson: jstring?, sortOption: jstring?) -> jstring {
    let tagsString = jstringToString(env, tagsJson)
    var tags: [Tag] = []
    if let data = tagsString.data(using: .utf8), let decoded = try? JSONDecoder().decode([Tag].self, from: data) {
        tags = decoded
    }
    let sortString = jstringToString(env, sortOption)
    let sort = SortOption(rawValue: sortString) ?? .popularity
    return stringToJString(env, encodeJSON(sdk.products(matching: tags, sortedBy: sort)))
}

/// Returns a single product by id as JSON, or an `ErrorEnvelope` JSON if the id is unknown.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetProduct")
public func nativeGetProduct(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, productId: jstring?) -> jstring {
    let id = jstringToString(env, productId)
    guard let product = sdk.product(id: id) else {
        return stringToJString(env, errorJSON("Product not found: \(id)"))
    }
    return stringToJString(env, encodeJSON(product))
}

/// Adds a quantity to the cart and returns the updated totals as JSON, or an error envelope on failure.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeAddToCart")
public func nativeAddToCart(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, productId: jstring?, quantity: jint) -> jstring {
    let id = jstringToString(env, productId)
    do {
        try sdk.addToCart(productId: id, quantity: Int(quantity))
        return stringToJString(env, encodeJSON(sdk.cartTotals()))
    } catch {
        return stringToJString(env, errorJSON("\(error)"))
    }
}

/// Overwrites a cart line's quantity and returns the updated totals as JSON, or an error envelope on failure.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeSetQuantity")
public func nativeSetQuantity(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, productId: jstring?, quantity: jint) -> jstring {
    let id = jstringToString(env, productId)
    do {
        try sdk.setQuantity(productId: id, quantity: Int(quantity))
        return stringToJString(env, encodeJSON(sdk.cartTotals()))
    } catch {
        return stringToJString(env, errorJSON("\(error)"))
    }
}

/// Removes a product's line from the cart and returns the updated totals as JSON.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeRemoveFromCart")
public func nativeRemoveFromCart(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, productId: jstring?) -> jstring {
    let id = jstringToString(env, productId)
    sdk.removeFromCart(productId: id)
    return stringToJString(env, encodeJSON(sdk.cartTotals()))
}

/// Empties the cart and returns the (now-zeroed) totals as JSON.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeClearCart")
public func nativeClearCart(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    sdk.clearCart()
    return stringToJString(env, encodeJSON(sdk.cartTotals()))
}

/// Applies a promo code (an empty string clears it) and returns the updated totals as JSON.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeApplyPromoCode")
public func nativeApplyPromoCode(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, code: jstring?) -> jstring {
    let codeString = jstringToString(env, code)
    sdk.applyPromoCode(codeString.isEmpty ? nil : codeString)
    return stringToJString(env, encodeJSON(sdk.cartTotals()))
}

/// Returns the current cart totals as JSON without mutating anything.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetCartTotals")
public func nativeGetCartTotals(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, encodeJSON(sdk.cartTotals()))
}

/// Submits the current cart for checkout (blocking) and returns the result as JSON.
@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeCheckout")
public func nativeCheckout(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, encodeJSON(sdk.checkoutSync()))
}
