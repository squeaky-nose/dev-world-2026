//
//  ProductListScreen.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop.ui.products

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.devworld.shop.bridge.dto.Product

private fun tagDisplayLabel(tag: String): String = tag.replaceFirstChar { it.uppercase() }

private fun sortDisplayLabel(sortOption: String): String = when (sortOption) {
    "popularity" -> "Popularity"
    "nameAscending" -> "A–Z"
    "nameDescending" -> "Z–A"
    else -> sortOption
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductListScreen(
    viewModel: ProductListViewModel,
    onProductClick: (Product) -> Unit,
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Products") },
                actions = {
                    FilterSortMenu(
                        tagLabel = uiState.selectedTag?.let(::tagDisplayLabel) ?: "All",
                        availableTags = uiState.availableTags,
                        selectedTag = uiState.selectedTag,
                        onTagSelected = viewModel::selectTag,
                        sortLabel = sortDisplayLabel(uiState.selectedSort),
                        availableSorts = uiState.availableSortOptions,
                        selectedSort = uiState.selectedSort,
                        onSortSelected = viewModel::selectSort,
                    )
                },
            )
        },
    ) { padding ->
        val listState = rememberLazyListState()

        // LazyColumn anchors scroll position to the previously-visible item's key, not its
        // index, so re-sorting/re-filtering would otherwise leave the new first item(s)
        // scrolled off-screen above the old anchor item. Snap back to the top instead.
        LaunchedEffect(uiState.selectedTag, uiState.selectedSort) {
            listState.scrollToItem(0)
        }

        LazyColumn(modifier = Modifier.padding(padding), state = listState) {
            items(uiState.products, key = { it.id }) { product ->
                ProductRow(product = product, onClick = { onProductClick(product) })
                HorizontalDivider()
            }
        }
    }
}

private enum class MenuLevel { None, Main, Filter, Sort }

@Composable
private fun FilterSortMenu(
    tagLabel: String,
    availableTags: List<String>,
    selectedTag: String?,
    onTagSelected: (String?) -> Unit,
    sortLabel: String,
    availableSorts: List<String>,
    selectedSort: String,
    onSortSelected: (String) -> Unit,
) {
    var level by remember { mutableStateOf(MenuLevel.None) }

    Box {
        IconButton(
            onClick = { level = MenuLevel.Main },
            modifier = Modifier.testTag("filterSortMenuButton"),
        ) {
            Icon(Icons.Filled.MoreVert, contentDescription = "Filter and sort")
        }

        DropdownMenu(expanded = level == MenuLevel.Main, onDismissRequest = { level = MenuLevel.None }) {
            DropdownMenuItem(
                text = { Text("Filter: $tagLabel") },
                onClick = { level = MenuLevel.Filter },
                modifier = Modifier.testTag("filterMenuItem"),
            )
            DropdownMenuItem(
                text = { Text("Sort: $sortLabel") },
                onClick = { level = MenuLevel.Sort },
                modifier = Modifier.testTag("sortMenuItem"),
            )
        }

        DropdownMenu(expanded = level == MenuLevel.Filter, onDismissRequest = { level = MenuLevel.None }) {
            DropdownMenuItem(
                text = { MenuOptionLabel("All", selectedTag == null) },
                onClick = {
                    onTagSelected(null)
                    level = MenuLevel.None
                },
                modifier = Modifier.testTag("filterOption_all"),
            )
            availableTags.forEach { tag ->
                DropdownMenuItem(
                    text = { MenuOptionLabel(tagDisplayLabel(tag), selectedTag == tag) },
                    onClick = {
                        onTagSelected(tag)
                        level = MenuLevel.None
                    },
                    modifier = Modifier.testTag("filterOption_$tag"),
                )
            }
        }

        DropdownMenu(expanded = level == MenuLevel.Sort, onDismissRequest = { level = MenuLevel.None }) {
            availableSorts.forEach { sort ->
                DropdownMenuItem(
                    text = { MenuOptionLabel(sortDisplayLabel(sort), selectedSort == sort) },
                    onClick = {
                        onSortSelected(sort)
                        level = MenuLevel.None
                    },
                    modifier = Modifier.testTag("sortOption_$sort"),
                )
            }
        }
    }
}

@Composable
private fun MenuOptionLabel(text: String, isSelected: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        if (isSelected) {
            Icon(Icons.Filled.Check, contentDescription = null, modifier = Modifier.size(18.dp))
        } else {
            Spacer(modifier = Modifier.size(18.dp))
        }
        Text(text)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProductRow(product: Product, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        onClick = onClick,
    ) {
        Row(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                AsyncImage(
                    model = product.imageURL,
                    contentDescription = product.name,
                    modifier = Modifier.size(56.dp).clip(RoundedCornerShape(8.dp)),
                    contentScale = ContentScale.Crop,
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(product.name, style = MaterialTheme.typography.titleMedium)
                    Text(
                        product.tags.joinToString(", ") { it.replaceFirstChar { c -> c.uppercase() } },
                        style = MaterialTheme.typography.bodySmall,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            Text("$${"%.2f".format(product.unitPrice)}", style = MaterialTheme.typography.bodyMedium)
        }
    }
}
