//
//  ShopFlowTest.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop

import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.devworld.shop.bridge.ShopSdkBridge
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** End-to-end instrumented UI tests driving the real app: filtering/sorting the product list,
 * and the full browse-add-promo-checkout flow. */
@RunWith(AndroidJUnit4::class)
class ShopFlowTest {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    /** Resets the native cart singleton before each test so tests don't leak state across runs. */
    @Before
    fun clearCart() {
        // The native cart singleton persists for the lifetime of the app process, which
        // instrumentation tests share across @Test methods within a run -- reset it so each
        // test starts from an empty cart regardless of run order.
        ShopSdkBridge.nativeClearCart()
    }

    /// Filter/Sort now live behind the trailing top app bar menu button, as a two-level menu:
    /// tap the trailing button, then the "Filter: …" or "Sort: …" item, then the option.
    private fun selectFilterOption(tagValue: String) {
        composeTestRule.onNodeWithTag("filterSortMenuButton").performClick()
        composeTestRule.onNodeWithTag("filterMenuItem").performClick()
        composeTestRule.onNodeWithTag("filterOption_$tagValue").performClick()
    }

    private fun selectSortOption(sortValue: String) {
        composeTestRule.onNodeWithTag("filterSortMenuButton").performClick()
        composeTestRule.onNodeWithTag("sortMenuItem").performClick()
        composeTestRule.onNodeWithTag("sortOption_$sortValue").performClick()
    }

    /** Verifies a tag filter stays applied across a navigation round-trip that mutates the cart. */
    @Test
    fun productFilterAppliesAndPersistsAcrossCartUpdates() {
        // Potatoes (vegetable) and Bananas (fruit) both rank near the top under the default
        // popularity sort, so both are visible without scrolling.
        composeTestRule.onNodeWithText("Potatoes").assertExists()

        selectFilterOption("fruit")

        // Filtering to Fruit should hide vegetables (Potatoes) and keep fruit (Bananas) visible.
        composeTestRule.onNodeWithText("Potatoes").assertDoesNotExist()
        composeTestRule.onNodeWithText("Bananas").assertExists()

        // Mutating the cart (which the tab badge / bottom nav reads) previously reset the
        // filter on iOS because the list view model was rebuilt from scratch on every
        // re-render. Confirm the Android view model doesn't have the same issue.
        composeTestRule.onNodeWithText("Bananas").performClick()
        composeTestRule.onNodeWithText("Add to Cart").performClick()
        composeTestRule.onNodeWithContentDescription("Back").performClick()

        composeTestRule.onNodeWithText("Bananas").assertExists()
        composeTestRule.onNodeWithText("Potatoes").assertDoesNotExist()
    }

    /** Verifies the default sort is popularity, and switching to A-Z actually reorders the list. */
    @Test
    fun defaultSortIsPopularityAndSortDropdownWorks() {
        // Default sort is popularity; Bananas has the highest hardcoded popularity (0.98).
        composeTestRule.onNodeWithText("Bananas").assertExists()
        composeTestRule.onNodeWithTag("filterSortMenuButton").performClick()
        composeTestRule.onNodeWithText("Sort: Popularity").assertExists()
        composeTestRule.onNodeWithTag("sortMenuItem").performClick()
        composeTestRule.onNodeWithTag("sortOption_nameAscending").performClick()

        // Avocado should now lead (alphabetically first across the whole catalog).
        composeTestRule.onNodeWithText("Avocado").assertExists()
    }

    /** Full happy-path flow: add multiple products (crossing the bulk-discount threshold),
     * verify computed totals, apply the promo code, verify the discounted total, then checkout
     * and confirm either an order-placed screen or a graceful failure message appears. */
    @Test
    fun browseAddToCartApplyPromoAndCheckout() {
        // Add 6x Potatoes (crosses the >5 bulk-discount threshold) and 2x Tomatoes -- both
        // visible without scrolling under the default popularity sort.
        composeTestRule.onNodeWithText("Potatoes").assertExists()
        composeTestRule.onNodeWithText("Potatoes").performClick()

        composeTestRule.onNodeWithText("Qty: 1").assertExists()
        repeat(5) { composeTestRule.onNodeWithText("+").performClick() } // 1 -> 6
        composeTestRule.onNodeWithText("Qty: 6").assertExists()
        composeTestRule.onNodeWithText("Add to Cart").performClick()
        composeTestRule.onNodeWithContentDescription("Back").performClick()

        composeTestRule.onNodeWithText("Tomatoes").performClick()
        composeTestRule.onNodeWithText("+").performClick() // 1 -> 2
        composeTestRule.onNodeWithText("Qty: 2").assertExists()
        composeTestRule.onNodeWithText("Add to Cart").performClick()
        composeTestRule.onNodeWithContentDescription("Back").performClick()

        // Cart tab.
        composeTestRule.onNodeWithText("Cart").performClick()
        composeTestRule.onNodeWithText("Potatoes").assertExists()
        composeTestRule.onNodeWithText("Tomatoes").assertExists()

        // Expected: Potatoes 6 * 1.20 with 10% bulk discount = 6.48; Tomatoes 2 * 2.60 = 5.20.
        // bulkDiscountedSubtotal = 11.68, shipping = 10 (under $30), grandTotal = 21.68.
        composeTestRule.onNode(hasText("21.68", substring = true)).assertExists()

        // Apply the devworld promo code: halves the 11.68 subtotal -> 5.84 merchandise + 10 shipping = 15.84.
        composeTestRule.onNodeWithText("Promo code").performTextInput("devworld")
        composeTestRule.onNodeWithText("Apply").performClick()

        composeTestRule.onNodeWithText("\"devworld\" applied").assertExists()
        composeTestRule.onNode(hasText("15.84", substring = true)).assertExists()

        // Checkout: performs a real POST. On success the cart is cleared and a dedicated
        // confirmation screen replaces the cart contents; on failure the inline error stays
        // on the normal cart screen (still showing the totals just asserted above).
        composeTestRule.onNodeWithText("Checkout").performClick()
        composeTestRule.waitUntil(timeoutMillis = 15_000) {
            composeTestRule
                .onAllNodesWithText("Order placed!")
                .fetchSemanticsNodes()
                .isNotEmpty() ||
                composeTestRule
                    .onAllNodes(hasText("Checkout failed", substring = true))
                    .fetchSemanticsNodes()
                    .isNotEmpty()
        }

        if (composeTestRule.onAllNodesWithText("Order placed!").fetchSemanticsNodes().isNotEmpty()) {
            composeTestRule.onNodeWithText("Continue Shopping").assertExists()
            composeTestRule.onNodeWithText("Continue Shopping").performClick()

            // The cart was cleared as part of checkout, so it should now show as empty.
            composeTestRule.onNodeWithText("Your cart is empty").assertExists()
        }
    }
}
