//
//  ShopViewModelFactory.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.devworld.shop.repo.ShopRepository
import com.devworld.shop.ui.cart.CartViewModel
import com.devworld.shop.ui.products.ProductListViewModel

/** Constructs the app's view models with the shared repository injected, for use with `viewModels { }`. */
class ShopViewModelFactory(private val repository: ShopRepository) : ViewModelProvider.Factory {
    /** Instantiates the requested view model type; throws for any type this factory doesn't know. */
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return when {
            modelClass.isAssignableFrom(ProductListViewModel::class.java) -> ProductListViewModel(repository) as T
            modelClass.isAssignableFrom(CartViewModel::class.java) -> CartViewModel(repository) as T
            else -> throw IllegalArgumentException("Unknown ViewModel class: $modelClass")
        }
    }
}
