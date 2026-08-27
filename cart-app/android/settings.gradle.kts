//
//  settings.gradle.kts
//  Shop
//
//  Created by Sushant Verma on 27/8/2026 for [/dev/world 2026](https://devworld.au/)
//

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "Shop"
include(":app")
