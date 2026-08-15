//
//  ProductListViewModel.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.ui.products

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devworld.shop.bridge.dto.Product
import com.devworld.shop.repo.ShopRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class ProductListUiState(
    val products: List<Product> = emptyList(),
    val availableTags: List<String> = emptyList(),
    val availableSortOptions: List<String> = emptyList(),
    val selectedTag: String? = null,
    val selectedSort: String = "popularity",
)

class ProductListViewModel(private val repository: ShopRepository) : ViewModel() {
    private val _uiState = MutableStateFlow(ProductListUiState())
    val uiState: StateFlow<ProductListUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch(Dispatchers.Default) {
            val tags = repository.getTags()
            val sortOptions = repository.getSortOptions()
            val products = repository.getProducts(emptyList(), _uiState.value.selectedSort)
            _uiState.update { it.copy(availableTags = tags, availableSortOptions = sortOptions, products = products) }
        }
    }

    fun selectTag(tag: String?) {
        _uiState.update { it.copy(selectedTag = tag) }
        reload()
    }

    fun selectSort(sortOption: String) {
        _uiState.update { it.copy(selectedSort = sortOption) }
        reload()
    }

    private fun reload() {
        viewModelScope.launch(Dispatchers.Default) {
            val state = _uiState.value
            val tags = state.selectedTag?.let { listOf(it) } ?: emptyList()
            val products = repository.getProducts(tags, state.selectedSort)
            _uiState.update { it.copy(products = products) }
        }
    }
}
