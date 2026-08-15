//
//  ShopFlowUITests.swift
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import XCTest

final class ShopFlowUITests: XCTestCase {

    /// Product rows are exposed as a single merged button (e.g. "Potatoes, Vegetable, USD 1.20"),
    /// not a separate static text for the name, so match on the label prefix.
    private func productButton(_ app: XCUIApplication, named name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    /// Nested submenu items (the leaf options) render as a different automation element type
    /// than the top-level menu buttons, so match on identifier across any element type.
    private func element(_ app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Filter/Sort now live behind the trailing nav bar menu button, as a nested menu: tap the
    /// trailing button, then the "Filter: …" or "Sort: …" submenu, then the option. The first two
    /// levels are reliably found by accessibility identifier, but SwiftUI converts the leaf-level
    /// items of a nested Menu into native UIMenu/UIAction elements that drop custom
    /// accessibilityIdentifiers, so those have to be matched by their visible label text instead.
    private func selectFilterOption(_ app: XCUIApplication, label: String) {
        element(app, identifier: "filterSortMenuButton").tap()
        element(app, identifier: "filterMenu").tap()
        app.buttons[label].tap()
    }

    private func selectSortOption(_ app: XCUIApplication, label: String) {
        element(app, identifier: "filterSortMenuButton").tap()
        element(app, identifier: "sortMenu").tap()
        app.buttons[label].tap()
    }

    func testProductFilterAppliesAndPersistsAcrossCartUpdates() {
        let app = XCUIApplication()
        app.launch()

        // Potatoes (vegetable) and Bananas (fruit) both rank near the top under the default
        // popularity sort, so both are visible without scrolling.
        XCTAssertTrue(productButton(app, named: "Potatoes").waitForExistence(timeout: 5))

        selectFilterOption(app, label: "Fruit")

        // Filtering to Fruit should hide vegetables (Potatoes) and keep fruit (Bananas) visible.
        XCTAssertFalse(productButton(app, named: "Potatoes").waitForExistence(timeout: 2))
        XCTAssertTrue(productButton(app, named: "Bananas").waitForExistence(timeout: 2))

        // Mutating the cart (which the tab badge reads, forcing AppRoot's body to
        // re-evaluate) previously reset the filter because ProductListViewModel was
        // being recreated from scratch on every re-render instead of persisted in @State.
        productButton(app, named: "Bananas").tap()
        XCTAssertTrue(app.buttons["Add to Cart"].waitForExistence(timeout: 5))
        app.buttons["Add to Cart"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap() // back to Products

        XCTAssertTrue(productButton(app, named: "Bananas").waitForExistence(timeout: 5))
        XCTAssertFalse(productButton(app, named: "Potatoes").exists, "Fruit filter should still be applied after a cart update")
    }

    func testDefaultSortIsPopularityAndSortDropdownWorks() {
        let app = XCUIApplication()
        app.launch()

        // Default sort is popularity; Bananas has the highest hardcoded popularity (0.98).
        XCTAssertTrue(productButton(app, named: "Bananas").waitForExistence(timeout: 5))

        // Switch to A-Z via the trailing menu's Sort submenu; Avocado should now lead
        // (alphabetically first across the whole catalog).
        selectSortOption(app, label: "A–Z")

        XCTAssertTrue(productButton(app, named: "Avocado").waitForExistence(timeout: 5))
    }

    func testBrowseAddToCartApplyPromoAndCheckout() {
        let app = XCUIApplication()
        app.launch()

        // Add 6x Potatoes (crosses the >5 bulk-discount threshold) and 2x Tomatoes -- both
        // visible without scrolling under the default popularity sort.
        XCTAssertTrue(productButton(app, named: "Potatoes").waitForExistence(timeout: 5))
        productButton(app, named: "Potatoes").tap()

        let incrementPotatoes = app.steppers.firstMatch.buttons["Increment"]
        XCTAssertTrue(incrementPotatoes.waitForExistence(timeout: 5))
        for _ in 0..<5 { incrementPotatoes.tap() } // 1 -> 6
        app.buttons["Add to Cart"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap() // back to Products

        XCTAssertTrue(productButton(app, named: "Tomatoes").waitForExistence(timeout: 5))
        productButton(app, named: "Tomatoes").tap()

        let incrementTomatoes = app.steppers.firstMatch.buttons["Increment"]
        XCTAssertTrue(incrementTomatoes.waitForExistence(timeout: 5))
        incrementTomatoes.tap() // 1 -> 2
        app.buttons["Add to Cart"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap() // back to Products

        // Cart tab.
        app.tabBars.buttons["Cart"].tap()
        XCTAssertTrue(app.staticTexts["Potatoes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Tomatoes"].exists)

        // Expected: Potatoes 6 * 1.20 with 10% bulk discount = 6.48; Tomatoes 2 * 2.60 = 5.20.
        // bulkDiscountedSubtotal = 11.68, shipping = 10 (under $30), grandTotal = 21.68.
        let totalBeforePromo = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "21.68")).firstMatch
        XCTAssertTrue(totalBeforePromo.waitForExistence(timeout: 5), "Expected a $21.68 total before promo code")

        // Apply the devworld promo code: halves the 11.68 subtotal -> 5.84 merchandise + 10 shipping = 15.84.
        let promoField = app.textFields["Enter code"]
        XCTAssertTrue(promoField.waitForExistence(timeout: 5))
        promoField.tap()
        promoField.typeText("devworld")
        app.buttons["Apply"].tap()

        XCTAssertTrue(app.staticTexts["\"devworld\" applied"].waitForExistence(timeout: 5))
        let totalAfterPromo = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "15.84")).firstMatch
        XCTAssertTrue(totalAfterPromo.waitForExistence(timeout: 5), "Expected a $15.84 total after promo code")

        // Checkout: performs a real POST. On success the cart is cleared and a dedicated
        // confirmation screen replaces the cart contents; on failure the inline error stays
        // on the normal cart screen (still showing the totals just asserted above).
        app.buttons["Checkout"].tap()
        let orderPlaced = app.staticTexts["Order placed!"]
        let anyFailure = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Checkout failed")).firstMatch
        XCTAssertTrue(
            orderPlaced.waitForExistence(timeout: 15) || anyFailure.waitForExistence(timeout: 1),
            "Expected the order confirmation screen (or a failure message) to appear"
        )

        if orderPlaced.exists {
            XCTAssertTrue(app.buttons["Continue Shopping"].exists)
            app.buttons["Continue Shopping"].tap()

            // The cart was cleared as part of checkout, so it should now show as empty.
            XCTAssertTrue(
                app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Your cart is empty")).firstMatch
                    .waitForExistence(timeout: 5),
                "Expected an empty cart after continuing shopping post-checkout"
            )
        }
    }
}
