//
//  Bridge.swift
//  shop-sdk-android-bridge
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import CJNI
import Foundation
import ShopSDK

private let sdk = ShopSDK()

private struct ErrorEnvelope: Codable {
    let error: String
}

private func encodeJSON<T: Encodable>(_ value: T) -> String {
    guard let data = try? JSONEncoder().encode(value), let string = String(data: data, encoding: .utf8) else {
        return "{\"error\":\"encoding failed\"}"
    }
    return string
}

private func errorJSON(_ message: String) -> String {
    encodeJSON(ErrorEnvelope(error: message))
}

private func jstringToString(_ env: UnsafeMutablePointer<JNIEnv?>, _ str: jstring?) -> String {
    guard let str else { return "" }
    let functions = env.pointee!.pointee
    guard let cString = functions.GetStringUTFChars(env, str, nil) else { return "" }
    defer { functions.ReleaseStringUTFChars(env, str, cString) }
    return String(cString: cString)
}

private func stringToJString(_ env: UnsafeMutablePointer<JNIEnv?>, _ string: String) -> jstring {
    let functions = env.pointee!.pointee
    return functions.NewStringUTF(env, string)!
}

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativePing")
public func nativePing(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, "pong")
}

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetTags")
public func nativeGetTags(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, encodeJSON(sdk.allTags()))
}

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetSortOptions")
public func nativeGetSortOptions(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, encodeJSON(sdk.allSortOptions()))
}

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

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetProduct")
public func nativeGetProduct(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, productId: jstring?) -> jstring {
    let id = jstringToString(env, productId)
    guard let product = sdk.product(id: id) else {
        return stringToJString(env, errorJSON("Product not found: \(id)"))
    }
    return stringToJString(env, encodeJSON(product))
}

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

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeRemoveFromCart")
public func nativeRemoveFromCart(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, productId: jstring?) -> jstring {
    let id = jstringToString(env, productId)
    sdk.removeFromCart(productId: id)
    return stringToJString(env, encodeJSON(sdk.cartTotals()))
}

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeClearCart")
public func nativeClearCart(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    sdk.clearCart()
    return stringToJString(env, encodeJSON(sdk.cartTotals()))
}

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeApplyPromoCode")
public func nativeApplyPromoCode(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject, code: jstring?) -> jstring {
    let codeString = jstringToString(env, code)
    sdk.applyPromoCode(codeString.isEmpty ? nil : codeString)
    return stringToJString(env, encodeJSON(sdk.cartTotals()))
}

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeGetCartTotals")
public func nativeGetCartTotals(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, encodeJSON(sdk.cartTotals()))
}

@_cdecl("Java_com_devworld_shop_bridge_ShopSdkBridge_nativeCheckout")
public func nativeCheckout(env: UnsafeMutablePointer<JNIEnv?>, thiz: jobject) -> jstring {
    stringToJString(env, encodeJSON(sdk.checkoutSync()))
}
