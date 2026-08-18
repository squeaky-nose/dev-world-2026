//
//  Main.kt
//  jvm-love
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

package love.jvm

import love.jvm.swifttrie.SwiftAVLScrabbleTrie
import love.jvm.swifttrie.WordSearchResult
import love.jvm.trie.AvlScrabbleTrie
import love.jvm.trie.scrabbleScore
import org.swift.swiftkit.ffm.AllocatingSwiftArena
import kotlin.system.exitProcess
import kotlin.system.measureNanoTime

private const val MAX_DISPLAY_RESULTS = 20

/**
 * One JVM process hosting two independent, from-scratch "self-balancing
 * trie" implementations: `AvlScrabbleTrie` runs natively in Kotlin, `SwiftAVLScrabbleTrie`
 * runs in-process in Swift, invoked here over swift-java's jextract FFM
 * bindings (see the README's Architecture section). Neither backend ever
 * runs as a separate OS process -- the Swift code is a dynamic library
 * loaded directly into this JVM.
 *
 * Interactive queries are Scrabble-style: `<pattern> [rack]`, where `pattern`
 * mixes literal letters with `_` (exactly one wildcard letter) and `*` (one
 * or more), every wildcard letter drawn from `rack` -- see README's "Query
 * grammar" section.
 */
fun main(args: Array<String>) {
    if (args.isEmpty()) {
        System.err.println("usage: jvm-love <path-to-word-list>")
        exitProcess(1)
    }
    val path = args[0]

    val kotlinTrie = AvlScrabbleTrie()
    kotlinTrie.buildFromFile(path)
    println(
        "Kotlin trie:  ${kotlinTrie.wordCount} words in ${"%.2f".format(kotlinTrie.buildTimeMillis)} ms"
    )

    AllocatingSwiftArena.ofConfined().use { arena ->
        val swiftTrie = SwiftAVLScrabbleTrie.init(arena)
        swiftTrie.buildFromFile(path)
        println(
            "Swift trie:   ${swiftTrie.wordCount()} words in ${"%.2f".format(swiftTrie.buildTimeMillis())} ms"
        )

        println()
        println("Enter a query as '<pattern> [rack]' (Ctrl-D to quit):")
        println("  pattern: literal letters, '_' = exactly one wildcard letter, '*' = one or more")
        println("  rack:    extra letters available to fill wildcards (optional)")
        generateSequence(::readLine).forEach { line ->
            val trimmed = line.trim()
            if (trimmed.isEmpty()) return@forEach

            val parts = trimmed.split(Regex("\\s+"), limit = 2)
            val pattern = parts[0]
            val rack = parts.getOrElse(1) { "" }
            if (pattern.isEmpty()) {
                println("  usage: <pattern> [rack] -- pattern can't be empty")
                return@forEach
            }

            println("\"$trimmed\":")
            runSearch(
                kotlinSearch = { kotlinTrie.findExactMatches(pattern, rack) },
                swiftSearch = { swiftTrie.findExactMatches(pattern, rack, arena) },
            )
        }
    }
}

/**
 * Runs the exact-match search against both backends and prints a 4-line
 * timing breakdown: Kotlin's result+time, Swift's result+outer/inner time,
 * a speed comparison (Kotlin vs Swift's *inner* time -- the apples-to-apples
 * figure, since neither includes the FFM crossing), and the FFM overhead
 * itself (outer - inner).
 */
private fun runSearch(
    kotlinSearch: () -> List<String>,
    swiftSearch: () -> WordSearchResult,
) {
    var kotlinWords: List<String> = emptyList()
    val kotlinNanos = measureNanoTime { kotlinWords = kotlinSearch() }
    val kotlinUs = kotlinNanos / 1000.0

    // Outer: wall-clock around the whole FFM call, measured from the JVM side --
    // includes downcall/marshalling overhead. Inner: Swift's own measurement of
    // just its search, returned as part of WordSearchResult (see AVLScrabbleTrie.swift).
    // The gap between them is the FFM crossing's cost.
    lateinit var swiftResult: WordSearchResult
    val swiftOuterNanos = measureNanoTime { swiftResult = swiftSearch() }
    val swiftWords = (0 until swiftResult.wordCount()).map { swiftResult.word(it) }
    val swiftInnerUs = swiftResult.searchTimeMillis() * 1000.0
    val swiftOuterUs = swiftOuterNanos / 1000.0
    val ffmOverheadUs = swiftOuterUs - swiftInnerUs

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

    println("  Kotlin: ${kotlinWords.size} word(s) (${"%.3f".format(kotlinUs)} us) -> ${formatWords(kotlinWords)}")
    println(
        "  Swift:  ${swiftWords.size} word(s) (outer ${"%.3f".format(swiftOuterUs)} us, " +
            "inner ${"%.3f".format(swiftInnerUs)} us) -> ${formatWords(swiftWords)}"
    )
    println("  $speedComparison")
    println(
        "  FFM overhead: ${"%.3f".format(ffmOverheadUs)} us " +
            "(${"%.1f".format(overheadPercent)}% of the Swift call)"
    )
}

/**
 * Both backends already return their word lists sorted by [scrabbleScore]
 * (highest first) -- this only adds the `[score]` annotation for display, so
 * it reuses Kotlin's own scoring function rather than re-deriving order.
 */
private fun formatWords(words: List<String>): String {
    if (words.isEmpty()) return "(none)"
    val shown = words.take(MAX_DISPLAY_RESULTS).joinToString(", ") { "$it [${scrabbleScore(it)}]" }
    val remaining = words.size - MAX_DISPLAY_RESULTS
    return if (remaining > 0) "$shown, ...and $remaining more" else shown
}
