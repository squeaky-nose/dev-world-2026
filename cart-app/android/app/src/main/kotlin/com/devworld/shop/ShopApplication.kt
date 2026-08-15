//
//  ShopApplication.kt
//  Shop
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package com.devworld.shop

import android.app.Application
import coil.ImageLoader
import coil.ImageLoaderFactory
import coil.disk.DiskCache
import com.devworld.shop.repo.ShopRepository
import okhttp3.OkHttpClient

class ShopApplication : Application(), ImageLoaderFactory {
    val repository: ShopRepository by lazy { ShopRepository() }

    // Wikimedia rejects requests with OkHttp's default User-Agent (HTTP 403); it requires
    // an identifying one per https://meta.wikimedia.org/wiki/User-Agent_policy.
    override fun newImageLoader(): ImageLoader =
        ImageLoader.Builder(this)
            .okHttpClient {
                OkHttpClient.Builder()
                    .addInterceptor { chain ->
                        chain.proceed(
                            chain.request().newBuilder()
                                .header("User-Agent", "ShopDemoApp/1.0 (contact: sushant.40@gmail.com)")
                                .build()
                        )
                    }
                    .build()
            }
            // Coil's default disk cache sizes itself to 2% of free disk space, which is
            // plenty for this catalog, but sizing it explicitly keeps the 50+ product
            // images reliably cached across launches instead of depending on device state.
            .diskCache {
                DiskCache.Builder()
                    .directory(cacheDir.resolve("image_cache"))
                    .maxSizeBytes(250L * 1024 * 1024)
                    .build()
            }
            .build()
}
