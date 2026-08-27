//
//  ProductDetailScreen.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.ui.products

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.devworld.shop.bridge.dto.Product
import com.devworld.shop.ui.cart.CartViewModel

/** Full-screen product detail: image, description, recipe ideas, a quantity stepper, and add-to-cart. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductDetailScreen(
    product: Product,
    cartViewModel: CartViewModel,
    onBack: () -> Unit,
) {
    var quantity by remember(product.id) { mutableIntStateOf(1) }
    // Counter (not a Boolean) so the "Added!" label logic stays uniform even if add-to-cart
    // is tapped more than once for the same product.
    var addedLabel by remember(product.id) { mutableIntStateOf(0) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(product.name) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { padding ->
        LazyColumn(modifier = Modifier.padding(padding)) {
            item {
                AsyncImage(
                    model = product.imageURL,
                    contentDescription = product.name,
                    modifier = Modifier.fillMaxWidth().height(220.dp),
                    contentScale = ContentScale.Crop,
                )
            }
            item {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("$${"%.2f".format(product.unitPrice)}", style = MaterialTheme.typography.titleMedium)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(product.description, style = MaterialTheme.typography.bodyLarge)
                }
            }
            if (product.recipeIdeas.isNotEmpty()) {
                item {
                    Text(
                        "Recipe ideas",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(horizontal = 16.dp),
                    )
                }
                items(product.recipeIdeas) { idea ->
                    Text("• $idea", modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp))
                }
            }
            item {
                Row(
                    modifier = Modifier.padding(16.dp).fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Button(onClick = { if (quantity > 1) quantity-- }) { Text("−") }
                    Text("Qty: $quantity", modifier = Modifier.wrapContentWidth())
                    Button(onClick = { quantity++ }) { Text("+") }
                }
                Button(
                    onClick = {
                        cartViewModel.addToCart(product.id, quantity) { addedLabel++ }
                    },
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                ) {
                    Text(if (addedLabel > 0) "Added!" else "Add to Cart")
                }
            }
        }
    }
}
