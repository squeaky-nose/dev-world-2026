//
//  Product.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

/// A single catalog item: display info, price, tags, and recipe suggestions.
public struct Product: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let imageURL: String
    public let unitPrice: Decimal
    public let tags: [Tag]
    public let recipeIdeas: [String]
    /// Hardcoded popularity score in 0...1, 1 being most popular. Used as the default sort order.
    public let popularity: Double

    /// Creates a product from its catalog fields.
    public init(
        id: String,
        name: String,
        description: String,
        imageURL: String,
        unitPrice: Decimal,
        tags: [Tag],
        recipeIdeas: [String],
        popularity: Double
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.unitPrice = unitPrice
        self.tags = tags
        self.recipeIdeas = recipeIdeas
        self.popularity = popularity
    }
}
