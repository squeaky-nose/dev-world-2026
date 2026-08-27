//
//  MainActivity.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.devworld.shop.bridge.dto.Product
import com.devworld.shop.ui.cart.CartScreen
import com.devworld.shop.ui.cart.CartViewModel
import com.devworld.shop.ui.products.ProductDetailScreen
import com.devworld.shop.ui.products.ProductListScreen
import com.devworld.shop.ui.products.ProductListViewModel

/** Single-activity host: builds the shared view models and hosts the Compose nav graph. */
class MainActivity : ComponentActivity() {

    private val factory by lazy { ShopViewModelFactory((application as ShopApplication).repository) }
    private val productListViewModel by viewModels<ProductListViewModel> { factory }
    private val cartViewModel by viewModels<CartViewModel> { factory }

    /** Sets the Compose content to the app's nav host, wrapped in the Material theme. */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                ShopNavHost(productListViewModel, cartViewModel)
            }
        }
    }
}

// Navigation route for the product list screen.
private const val ROUTE_PRODUCTS = "products"
// Navigation route for the cart screen.
private const val ROUTE_CART = "cart"
// Navigation route for the product detail screen.
private const val ROUTE_DETAIL = "productDetail"

/**
 * Root nav graph: switches between the product list, cart, and product detail screens, and
 * hides the bottom bar while on the detail screen.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ShopNavHost(
    productListViewModel: ProductListViewModel,
    cartViewModel: CartViewModel,
) {
    val navController = rememberNavController()
    // Passed to the detail route via shared state rather than a nav argument, since Product
    // isn't a simple serializable nav-arg type here.
    var selectedProduct by remember { mutableStateOf<Product?>(null) }
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val showBottomBar = currentRoute != ROUTE_DETAIL

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                ShopBottomBar(navController, currentRoute, cartViewModel)
            }
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = ROUTE_PRODUCTS,
            modifier = Modifier.padding(padding),
        ) {
            composable(ROUTE_PRODUCTS) {
                ProductListScreen(
                    viewModel = productListViewModel,
                    onProductClick = { product ->
                        selectedProduct = product
                        navController.navigate(ROUTE_DETAIL)
                    },
                )
            }
            composable(ROUTE_CART) {
                CartScreen(viewModel = cartViewModel)
            }
            composable(ROUTE_DETAIL) {
                selectedProduct?.let { product ->
                    ProductDetailScreen(
                        product = product,
                        cartViewModel = cartViewModel,
                        onBack = { navController.popBackStack() },
                    )
                }
            }
        }
    }
}

/** Bottom navigation bar with Products/Cart tabs; the Cart tab shows a badge with the line count. */
@Composable
private fun ShopBottomBar(navController: NavHostController, currentRoute: String?, cartViewModel: CartViewModel) {
    val totals by cartViewModel.totals.collectAsState()

    NavigationBar {
        NavigationBarItem(
            selected = currentRoute == ROUTE_PRODUCTS,
            onClick = {
                navController.navigate(ROUTE_PRODUCTS) {
                    popUpTo(ROUTE_PRODUCTS) { inclusive = true }
                }
            },
            icon = { Icon(Icons.Filled.List, contentDescription = "Products") },
            label = { Text("Products") },
        )
        NavigationBarItem(
            selected = currentRoute == ROUTE_CART,
            onClick = {
                navController.navigate(ROUTE_CART) {
                    popUpTo(ROUTE_PRODUCTS)
                }
            },
            icon = {
                BadgedBox(badge = {
                    if (totals.lines.isNotEmpty()) {
                        Badge { Text("${totals.lines.size}") }
                    }
                }) {
                    Icon(Icons.Filled.ShoppingCart, contentDescription = "Cart")
                }
            },
            label = { Text("Cart") },
        )
    }
}
