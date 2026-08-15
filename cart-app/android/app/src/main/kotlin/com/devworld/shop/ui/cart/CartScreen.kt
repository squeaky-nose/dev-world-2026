//
//  CartScreen.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.ui.cart

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.devworld.shop.bridge.dto.CartLine

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CartScreen(viewModel: CartViewModel) {
    val totals by viewModel.totals.collectAsState()
    val productsById by viewModel.productsById.collectAsState()
    val promoCodeText by viewModel.promoCodeText.collectAsState()
    val isCheckingOut by viewModel.isCheckingOut.collectAsState()
    val checkoutResult by viewModel.checkoutResult.collectAsState()
    val orderPlaced by viewModel.orderPlaced.collectAsState()

    Scaffold(topBar = { TopAppBar(title = { Text("Cart") }) }) { padding ->
        if (orderPlaced) {
            OrderConfirmation(
                modifier = Modifier.fillMaxSize().padding(padding),
                onContinueShopping = viewModel::continueShopping,
            )
            return@Scaffold
        }

        if (totals.lines.isEmpty()) {
            Column(
                modifier = Modifier.fillMaxSize().padding(padding),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text("Your cart is empty", style = MaterialTheme.typography.bodyLarge)
            }
            return@Scaffold
        }

        LazyColumn(modifier = Modifier.padding(padding).fillMaxWidth()) {
            items(totals.lines, key = { it.productId }) { line ->
                CartLineRow(
                    line = line,
                    name = productsById[line.productId]?.name ?: line.productId,
                    onQuantityChange = { viewModel.setQuantity(line.productId, it) },
                    onRemove = { viewModel.remove(line.productId) },
                )
                HorizontalDivider()
            }

            item {
                Column(modifier = Modifier.padding(16.dp).fillMaxWidth()) {
                    OutlinedTextField(
                        value = promoCodeText,
                        onValueChange = viewModel::updatePromoCodeText,
                        label = { Text("Promo code") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(onClick = viewModel::applyPromoCode, modifier = Modifier.fillMaxWidth()) {
                        Text("Apply")
                    }
                    if (totals.promoCode != null) {
                        Text(
                            "\"${totals.promoCode}\" applied",
                            color = Color(0xFF2E7D32),
                            modifier = Modifier.padding(top = 4.dp),
                        )
                    }
                }
            }

            item {
                Column(modifier = Modifier.padding(horizontal = 16.dp)) {
                    SummaryRow("Subtotal", totals.bulkDiscountedSubtotal)
                    if (totals.promoDiscount > 0) {
                        SummaryRow("Promo discount", -totals.promoDiscount)
                    }
                    SummaryRow("Shipping", totals.shipping)
                    HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                    SummaryRow("Total", totals.grandTotal, emphasized = true)
                }
            }

            item {
                Column(modifier = Modifier.padding(16.dp).fillMaxWidth()) {
                    Button(
                        onClick = viewModel::checkout,
                        enabled = !isCheckingOut,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        if (isCheckingOut) {
                            CircularProgressIndicator(modifier = Modifier.height(20.dp), color = Color.White)
                        } else {
                            Text("Checkout")
                        }
                    }
                    checkoutResult?.let { result ->
                        Text(
                            result.message,
                            color = if (result.success) Color(0xFF2E7D32) else Color(0xFFC62828),
                            modifier = Modifier.padding(top = 8.dp),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun OrderConfirmation(onContinueShopping: () -> Unit, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(
            Icons.Filled.CheckCircle,
            contentDescription = null,
            tint = Color(0xFF2E7D32),
            modifier = Modifier.size(64.dp),
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text("Order placed!", style = MaterialTheme.typography.headlineSmall)
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            "Thanks for your order. Your cart is ready for next time.",
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 32.dp),
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = onContinueShopping) {
            Text("Continue Shopping")
        }
    }
}

@Composable
private fun CartLineRow(
    line: CartLine,
    name: String,
    onQuantityChange: (Int) -> Unit,
    onRemove: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Text(name, style = MaterialTheme.typography.titleMedium)
            Text("$${"%.2f".format(line.lineTotal)}", style = MaterialTheme.typography.bodyMedium)
            if (line.lineDiscount > 0) {
                Text("Bulk discount applied", color = Color(0xFF2E7D32), style = MaterialTheme.typography.bodySmall)
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = { if (line.quantity > 1) onQuantityChange(line.quantity - 1) }) { Text("−") }
            Text("${line.quantity}")
            TextButton(onClick = { onQuantityChange(line.quantity + 1) }) { Text("+") }
            TextButton(onClick = onRemove) { Text("Remove") }
        }
    }
}

@Composable
private fun SummaryRow(label: String, value: Double, emphasized: Boolean = false) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        val style = if (emphasized) MaterialTheme.typography.titleMedium else MaterialTheme.typography.bodyMedium
        Text(label, style = style)
        Text("$${"%.2f".format(value)}", style = style)
    }
}
