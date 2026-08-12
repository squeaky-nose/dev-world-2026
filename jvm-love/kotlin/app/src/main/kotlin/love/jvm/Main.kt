package love.jvm

import love.jvm.swifttrie.LookupResult
import love.jvm.swifttrie.SwiftAVLTrie
import love.jvm.trie.AvlTrie
import org.swift.swiftkit.ffm.AllocatingSwiftArena
import kotlin.system.exitProcess
import kotlin.system.measureNanoTime

/**
 * One JVM process hosting two independent, from-scratch "self-balancing
 * trie" implementations: `AvlTrie` runs natively in Kotlin, `SwiftAVLTrie`
 * runs in-process in Swift, invoked here over swift-java's jextract FFM
 * bindings (see the README's Architecture section). Neither backend ever
 * runs as a separate OS process -- the Swift code is a dynamic library
 * loaded directly into this JVM.
 */
fun main(args: Array<String>) {
    if (args.isEmpty()) {
        System.err.println("usage: jvm-love <path-to-word-list>")
        exitProcess(1)
    }
    val path = args[0]

    val kotlinTrie = AvlTrie()
    kotlinTrie.buildFromFile(path)
    println(
        "Kotlin trie:  ${kotlinTrie.wordCount} words in ${"%.2f".format(kotlinTrie.buildTimeMillis)} ms"
    )

    AllocatingSwiftArena.ofConfined().use { arena ->
        val swiftTrie = SwiftAVLTrie.init(arena)
        swiftTrie.buildFromFile(path)
        println(
            "Swift trie:   ${swiftTrie.wordCount()} words in ${"%.2f".format(swiftTrie.buildTimeMillis())} ms"
        )

        println()
        println("Enter words to look up (Ctrl-D to quit):")
        generateSequence(::readLine).forEach { line ->
            val word = line.trim()
            if (word.isEmpty()) return@forEach

            var kotlinFound = false
            val kotlinNanos = measureNanoTime { kotlinFound = kotlinTrie.contains(word) }

            // Outer: wall-clock around the whole FFM call, measured from the JVM side --
            // includes downcall/marshalling overhead. Inner: Swift's own measurement of
            // just its lookup walk, returned as part of LookupResult (see AVLTrie.swift).
            // The gap between them is the FFM crossing's cost.
            lateinit var swiftResult: LookupResult
            val swiftOuterNanos = measureNanoTime { swiftResult = swiftTrie.contains(word, arena) }
            val kotlinUs = kotlinNanos / 1000.0
            val swiftInnerUs = swiftResult.lookupTimeMillis * 1000.0
            val swiftOuterUs = swiftOuterNanos / 1000.0
            val ffmOverheadUs = swiftOuterUs - swiftInnerUs

            // Kotlin vs Swift's inner time is the apples-to-apples comparison (both are
            // pure trie-walk time, with no FFM crossing in either figure).
            val speedDiffUs = kotlin.math.abs(kotlinUs - swiftInnerUs)
            val slowerUs = maxOf(kotlinUs, swiftInnerUs)
            val speedDiffPercent = if (slowerUs > 0) speedDiffUs / slowerUs * 100.0 else 0.0
            val speedComparison = when {
                kotlinUs < swiftInnerUs ->
                    "Kotlin is faster than Swift by ${"%.3f".format(speedDiffUs)} us (${"%.1f".format(speedDiffPercent)}%)"
                swiftInnerUs < kotlinUs ->
                    "Swift is faster than Kotlin by ${"%.3f".format(speedDiffUs)} us (${"%.1f".format(speedDiffPercent)}%)"
                else -> "Kotlin and Swift took the same time"
            }

            val overheadPercent = if (swiftOuterUs > 0) ffmOverheadUs / swiftOuterUs * 100.0 else 0.0

            println("  \"$word\":")
            println("    Kotlin: ${found(kotlinFound)} (${"%.3f".format(kotlinUs)} us)")
            println(
                "    Swift:  ${found(swiftResult.isFound)} (outer ${"%.3f".format(swiftOuterUs)} us, " +
                    "inner ${"%.3f".format(swiftInnerUs)} us)"
            )
            println("    $speedComparison")
            println(
                "    FFM overhead: ${"%.3f".format(ffmOverheadUs)} us " +
                    "(${"%.1f".format(overheadPercent)}% of the Swift call)"
            )
        }
    }
}

private fun found(value: Boolean) = if (value) "found    " else "not found"
