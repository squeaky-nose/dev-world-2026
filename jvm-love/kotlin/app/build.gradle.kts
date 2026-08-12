plugins {
    kotlin("jvm") version "2.2.20"
    application
}

group = "love.jvm"
version = "0.1.0"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(25))
    }
}

// Kotlin 2.2.x's compiler doesn't have a JVM_25 target enum yet (JVM_24 is
// its ceiling), but swiftkit-ffm's jar declares itself buildable only by
// consumers requesting JVM 25+ (it's built with `swiftJavaJdk=25`, see
// vendor/swift-java/settings.gradle.kts). Bytecode targeting 24 runs fine on
// the JDK 25 runtime we actually execute on, so this is a real bytecode
// constraint, not a build-tool one: force the classpath's requested
// TargetJvmVersion to 25 so Gradle's variant matching accepts swiftkit-ffm,
// while compiling our own code at 24, the highest Kotlin can currently emit.
tasks.withType<JavaCompile>().configureEach {
    options.release.set(24)
}
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_24)
    }
}
configurations.matching { it.name == "compileClasspath" || it.name == "runtimeClasspath" }.configureEach {
    attributes {
        attribute(org.gradle.api.attributes.java.TargetJvmVersion.TARGET_JVM_VERSION_ATTRIBUTE, 25)
    }
}

repositories {
    mavenLocal()
    mavenCentral()
}

val vendorSwiftJavaDir = file("$rootDir/vendor/swift-java")
val swiftPackageDir = file("$rootDir/swift/JvmLoveTrie")
val swiftTargetName = "JvmLoveTrie"

// swift-java is pre-1.0 with no source-stability guarantee (see README ->
// Prerequisites), so we vendor + pin an exact commit (`make setup`) rather
// than depending on a moving Maven Central release. `git describe` mirrors
// exactly how swift-java's own Gradle build resolves its published version
// (BuildLogic/.../gitVersion.kt), so the version we ask for here always
// matches what `make setup`'s `publishToMavenLocal` actually produced.
fun resolveSwiftJavaVersion(): String =
    try {
        val process = ProcessBuilder("git", "describe", "--tags", "--always")
            .directory(vendorSwiftJavaDir)
            .redirectErrorStream(true)
            .start()
        val output = process.inputStream.bufferedReader().readText().trim()
        if (process.waitFor() == 0 && output.isNotBlank()) output else "0.0.0-SNAPSHOT"
    } catch (e: Exception) {
        "0.0.0-SNAPSHOT"
    }

val swiftJavaVersion = resolveSwiftJavaVersion()

dependencies {
    implementation("org.swift.swiftkit:swiftkit-core:$swiftJavaVersion")
    implementation("org.swift.swiftkit:swiftkit-ffm:$swiftJavaVersion")
}

// Compiles the Swift trie dylib and, via the JExtractSwiftPlugin build
// plugin applied in swift/JvmLoveTrie/Package.swift, generates the Java
// bindings Kotlin calls into -- both as a side effect of one `swift build`.
val swiftBuild = tasks.register<Exec>("swiftBuild") {
    description = "Compile the Swift trie dylib and generate jextract Java bindings"
    workingDir = swiftPackageDir
    commandLine("swift", "build", "--disable-experimental-prebuilts")
    inputs.file(swiftPackageDir.resolve("Package.swift"))
    inputs.dir(swiftPackageDir.resolve("Sources"))
    outputs.dir(swiftPackageDir.resolve(".build"))
}

// SwiftPM's build-plugin output path convention: .build/plugins/outputs/<package-dir-name-lowercased>/<target>/destination/<PluginName>/...
val jextractGeneratedJavaDir =
    swiftPackageDir.resolve(".build/plugins/outputs/${swiftPackageDir.name.lowercase()}/$swiftTargetName/destination/JExtractSwiftPlugin/src/generated/java")

sourceSets {
    main {
        java.srcDir(jextractGeneratedJavaDir)
    }
}

tasks.named("compileJava") { dependsOn(swiftBuild) }
tasks.named("compileKotlin") { dependsOn(swiftBuild) }

// SwiftPM builds our dylib and its swift-java dependencies (libSwiftJava,
// libSwiftRuntimeFunctions) into one shared output dir with @loader_path
// rpaths between them, so a single java.library.path entry covers all three;
// libswiftCore itself resolves via SwiftLibraries' /usr/lib/swift fallback.
val swiftDylibDir = swiftPackageDir.resolve(".build/out/Products/Debug")

application {
    mainClass.set("love.jvm.MainKt")
    applicationDefaultJvmArgs = listOf(
        "--enable-native-access=ALL-UNNAMED",
        "-Djava.library.path=$swiftDylibDir",
    )
}
