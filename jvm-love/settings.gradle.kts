//
//  settings.gradle.kts
//  jvm-love
//
//  Created by Sushant Verma on 27/8/2026 for [/dev/world 2026](https://devworld.au/)
//

rootProject.name = "jvm-love"

include(":app")
project(":app").projectDir = file("kotlin/app")
