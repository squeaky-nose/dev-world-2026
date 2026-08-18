# jvm-love

A command-line Scrabble word finder that builds the same word list into two
independent, from-scratch **self-balancing trie** implementations — one
native Kotlin, one native Swift — inside a *single JVM process*, then answers
wildcard + rack queries against both backends side by side.

```
$ make run
Kotlin trie:  79339 words in 33.07 ms
Swift trie:   79339 words in 137.08 ms

Enter a query as '<pattern> [rack]' (Ctrl-D to quit):
  pattern: literal letters, '_' = exactly one wildcard letter, '*' = one or more
  rack:    extra letters available to fill wildcards (optional)
"po* tato":
  Kotlin: 3 word(s) (5601.375 us) -> potato [8], potto [7], pot [5]
  Swift:  3 word(s) (outer 5295.000 us, inner 1413.000 us) -> potato [8], potto [7], pot [5]
  Swift is faster than Kotlin by 4188.375 us (74.8%)
  FFM overhead: 3882.000 us (73.3% of the Swift call)
```

Every query runs one search — dictionary words that fully match `pattern`
end to end, with wildcards filled from `rack` (see "Query grammar" below) —
against **both** backends, printing a 4-line breakdown:
1. **Kotlin** — the result count + word list (sorted highest-scoring first,
   each word annotated `[score]` under standard English Scrabble letter
   values — see "Scoring" below), timed with `measureNanoTime` around
   `AvlTrie.findExactMatches`.
2. **Swift** — the result count + word list, timed two ways: **outer** is
   `measureNanoTime` around the whole call from Kotlin (includes FFM
   downcall/marshalling cost); **inner** is `WordSearchResult.searchTimeMillis`,
   timed *inside* Swift with `ContinuousClock`, covering only the search
   itself. Results are exposed as indexed getters (`wordCount()`/`word(at:)`)
   on `WordSearchResult` rather than returning a Swift `Array` directly —
   jextract's FFM mode doesn't support extracting collection-typed return
   values, only scalars, strings, and nominal types built from those.
3. **Speed comparison** — Kotlin's time vs. Swift's *inner* time (the
   apples-to-apples comparison: both are pure search time, with no FFM
   crossing in either figure), reporting which was faster and by how much,
   in both µs and relative %.
4. **FFM overhead** — `outer - inner`: what crossing the JVM/native boundary
   actually costs, as µs and as a percentage of the whole Swift call. The
   FFM downcall stub pays a one-time warmup cost on its first invocation of
   a given generated method — expect a large overhead on the very first
   query, then tens-to-hundreds of µs afterward.

Both backends' word lists are printed side by side (capped at 20 words, then
`...and N more`) so any divergence between the two independent
implementations is visible at a glance, not just their counts.

## Query grammar

Each line of input is `<pattern> [rack]` (whitespace-separated; `rack`
defaults to empty). `pattern` is a sequence of per-character tokens:

- a **literal letter** — matches exactly that letter (a tile already on the
  board)
- **`_`** — matches exactly **one** wildcard letter
- **`*`** — matches **one or more** consecutive wildcard letters

Every wildcard letter (`_` or `*`) must be drawn from `rack` — not any letter
of the alphabet — mirroring real Scrabble: fixed pattern letters are tiles
already placed on the board, wildcard positions are empty squares you can
only fill with tiles from your own hand. Each rack letter is usable at most
once per candidate word. A plain word with no wildcards (`test`) is valid
input with an empty rack — it degenerates to a plain dictionary membership
check.

The search is always anchored at both ends — `pattern` must match the whole
word, not a prefix or substring — and letter *positions* matter: unlike an
anagram search, a pattern's literal letters must appear exactly where they're
written. `*` only means the *span it covers* is variable-length, not that its
contents can land anywhere else in the word.

Worked examples: `test` (all-literal, a plain membership check) ·
`_pp_e al` (two single-letter wildcards) · `*pp*e al` (two variable-length
wildcards; matches `apple` — the first `*` consumes `a`, the second consumes
`l`) · `po* tato` (matches `pot`, `potato`, `potto`, etc. — but *not* `otto`,
since the pattern's leading `po` must appear at the start of the word).

## Scoring

Each matched word is scored under standard English Scrabble letter values
(1 point: A, E, I, O, U, L, N, S, T, R · 2: D, G · 3: B, C, M, P · 4: F, H,
V, W, Y · 5: K · 8: J, X · 10: Q, Z) and results come back **sorted
highest-scoring first**.

The point table and `scrabbleScore` function are implemented independently
in both `AvlTrie.kt` and `AVLTrie.swift` — each backend scores and sorts its
*own* results before returning them from `findExactMatches`, so the sort is
part of what's being timed, not a step Kotlin adds afterward. `Main.kt`
reuses Kotlin's own `scrabbleScore` purely to render the `[score]`
annotation next to each word it prints (including Swift's already-sorted
results) — it never uses that call to *decide* order, since each backend
already returned its list correctly sorted.

## Architecture

There is only **one OS process**: the JVM. The Swift trie is compiled to a
dynamic library (`libJvmLoveTrie.dylib`) and loaded directly into that JVM
using [swift-java](https://github.com/swiftlang/swift-java)'s `jextract` FFM
mode (the toolchain demoed in WWDC25 session
["Explore Swift and Java interoperability"](https://developer.apple.com/videos/play/wwdc2025/307/)).
Calling into Swift from Kotlin is an in-process function call through
generated bindings built on Java's [Foreign Function & Memory
API](https://openjdk.org/jeps/454) — not IPC, not a subprocess, not JNI glue
you write by hand.

```
kotlin/app/  (Gradle "app" project — the thing you run)
├── src/main/kotlin/love/jvm/
│   ├── Main.kt                 builds both tries, runs the stdin wildcard-search loop
│   └── trie/AvlTrie.kt          Kotlin trie — pure JVM code
└── build.gradle.kts             also drives the Swift build (see below)

swift/JvmLoveTrie/  (SwiftPM package — the Swift half)
└── Sources/JvmLoveTrie/
    ├── AVLTrie.swift             Swift trie — independent implementation, same algorithm
    └── swift-java.config         tells jextract what Java package to generate into

vendor/swift-java/   pinned checkout of swift-java itself (see Versions below;
                     not committed to git -- `make setup` clones it)
```

`kotlin/app/build.gradle.kts` wires the two halves together: its `compileKotlin`
task depends on a `swiftBuild` task that runs `swift build` in
`swift/JvmLoveTrie`. That one SwiftPM build both compiles the trie into a
dylib *and* (via the `JExtractSwiftPlugin` build plugin declared in
`swift/JvmLoveTrie/Package.swift`) generates the Java source files that let
Kotlin call it — so `love.jvm.swifttrie.SwiftAVLTrie` (the Kotlin-visible
handle onto the Swift class) doesn't exist in this repo; it's generated fresh
into `swift/JvmLoveTrie/.build/plugins/outputs/.../src/generated/java` on
every build. `Main.kt` allocates a confined `AllocatingSwiftArena` for the
lifetime of the Swift trie, the mechanism FFM mode uses to tie a Swift
object's native memory lifetime to a scope on the Java side.

Each backend reads the word-list file **itself** — the file path is the only
thing that crosses the Kotlin/Swift boundary. Neither trie implementation
shares code, algorithms notes, or data with the other; they're two answers to
the same assignment.

### What "self-balancing" means here

Neither language uses a textbook AVL/red-black tree *as* the trie — trie
depth is fixed by word length, not insertion order, so there's nothing to
balance there. What *can* go skewed is **the set of children at each node**:
a classic trie stores those in a flat array or hash map, but this project
stores each node's children in their own small **AVL-balanced binary search
tree**, keyed by character. That bounds child lookup at any single node to
O(log k) (k = that node's distinct child count) instead of an unbalanced
BST's worst case of O(k) — self-balancing applied to the trie's branching
structure, not its depth. Both `AvlTrie.kt` and `AVLTrie.swift` implement the
same rotation logic (`rotateLeft`/`rotateRight`/`rebalance`) independently.

This is also why a trie suits wildcard/rack search better than a B-tree or a
hash set: `findExactMatches` is a backtracking search that only ever branches
into a node's **actual, already-inserted** children (`TrieNode.children()`/
`Node.children()`) — a wildcard or rack letter that isn't a real
next-character anywhere in the dictionary prunes that branch immediately,
for free. A hash set would need to generate and individually probe every
combinatorially-possible candidate string first; a B-tree gives ordered
whole-key comparisons, not per-character branching, so it has no equivalent
way to prune mid-word.

### Case sensitivity

Both tries lowercase every word — on insertion (`AvlTrie.insert` /
`SwiftAVLTrie.insert`) and on search (`AvlTrie.findExactMatches`, mirrored by
`SwiftAVLTrie.findExactMatches`) — so `"Zebra"`, `"ZEBRA"`, and `"zebra"` all
hit the same node, regardless of how you type a query. `ospd.txt` (the
default word list) is already all-lowercase with no case-variant duplicates,
so this doesn't visibly change its reported word count; it would if you
pointed `WORDS` at a list with mixed-case entries (e.g. macOS's
`/usr/share/dict/words`, which has both `"Aardvark"` and `"aardvark"` as
separate lines for some words) — case-variant duplicates collapse into one
trie entry, so the reported count would come in slightly *lower* than the
raw line count.

## Prerequisites

- **Swift 6.2+** (this project is built/tested against Apple Swift 6.5-dev).
  Install via [swiftly](https://www.swift.org/swiftly/):
  ```
  swiftly install main-snapshot
  ```
- **JDK 25+** — required by swift-java's FFM mode ([JEP 454](https://openjdk.org/jeps/454)
  was finalized in JDK 22, but swift-java validates against 25). Install via
  [SDKMAN!](https://sdkman.io/):
  ```
  sdk install java 25-amzn
  ```
  Make sure `JAVA_HOME` points at it.
- **Gradle** (used to drive the Kotlin build and to `publishToMavenLocal` the
  vendored swift-java libraries). This project doesn't ship a Gradle
  wrapper for swift-java itself, so a system Gradle is needed for `make setup`:
  ```
  brew install gradle
  ```
- **git** (to clone the pinned swift-java checkout in `make setup`).

[`ospd.txt`](ospd.txt) (the Official Scrabble Players Dictionary, one word
per line) at the project root is used as the default word list — fitting,
given the whole point of this app.

## Versions

Exact versions this project is currently built and tested against:

| Component | Version |
|---|---|
| Swift | Apple Swift 6.5-dev (`arm64-apple-macosx`) |
| JDK | 25 (Corretto 25.0.1) |
| Gradle | 9.1.0 (wrapper, for `kotlin/app`) / system Gradle (for `make setup`'s swift-java build) |
| Kotlin | 2.2.20 |
| [swift-java](https://github.com/swiftlang/swift-java) | pinned to [`2dd2c60`](https://github.com/swiftlang/swift-java/commit/2dd2c6043f63d0d2cd99dfdcc8f058949f0309f3) (2026-08-11), just past the `0.5.1` tag |

**Why pinned, not a release:** swift-java is pre-1.0 and explicitly
[does not guarantee source stability](https://github.com/swiftlang/swift-java/releases/tag/0.1.0)
between versions, and its FFM interop libraries aren't published to Maven
Central at all — `make setup` builds and `publishToMavenLocal`s them from
source. Pinning an exact commit (rather than tracking `main`) keeps the
generated bindings this project's Kotlin code was written against from
silently changing shape underneath it.

## Quick start

```
make setup    # one-time: clone+pin vendor/swift-java, publish its libs to ~/.m2
make run      # build (if needed) and run interactively against ospd.txt
```

Run `make` (or `make help`) to list all available targets. Use a different
word list with:

```
make run WORDS=/path/to/your/wordlist.txt
```

The word list format is one word per line (blank lines are skipped); this is
exactly the format `ospd.txt` is already in.

## How the Makefile works

- `make setup` clones [`swiftlang/swift-java`](https://github.com/swiftlang/swift-java)
  into `vendor/swift-java` at the exact commit pinned above (skipped if that
  directory already exists — re-run after `make distclean` to re-pin), then
  runs *its* Gradle build's `publishToMavenLocal`, which builds and installs
  the `swiftkit-core`/`swiftkit-ffm` Java libraries (the JVM-side runtime
  the generated bindings call into) to `~/.m2`. This is a one-time step;
  ordinary `make build`/`make run` don't touch it.
- `make build` runs `./gradlew :app:installDist` rather than a plain
  `gradle build`, so `make run` can invoke the generated launcher script
  (`kotlin/app/build/install/app/bin/app`) directly instead of going through
  `gradle run` — **Gradle's `run` task doesn't forward the calling shell's
  stdin to the forked JVM by default**, which silently breaks the
  interactive query loop when input is piped in (`make run` needs this
  to work for both an interactive terminal session and piped/scripted input).
  This target fails fast with a clear error if `make setup` hasn't been run
  yet, since `:app:compileKotlin`'s dependency on the Maven-local swift-java
  artifacts would otherwise fail with a much less obvious "could not resolve"
  error.
- `make run` depends on `build`, so it's always safe to run directly — it
  just does nothing extra if nothing changed.
- `make clean` removes Kotlin/Swift build outputs but leaves
  `vendor/swift-java` and `~/.m2` alone, since those are the expensive parts
  to reproduce. `make distclean` additionally removes `vendor/swift-java`,
  forcing the next `make setup` to re-clone and re-publish from scratch.

## Known rough edges

- **Kotlin's JVM target enum lags the JDK.** Kotlin 2.2.20's compiler has no
  `JVM_25` target yet (`JVM_24` is its ceiling), but swift-java's
  `swiftkit-ffm` artifact declares itself buildable only against JVM 25+
  consumers. `kotlin/app/build.gradle.kts` works around this by compiling at
  bytecode level 24 (which still runs fine on a JDK 25 runtime) while
  overriding the classpath's requested `TargetJvmVersion` attribute to 25 so
  Gradle's variant matching accepts the dependency. This is a real bytecode
  ceiling in the Kotlin compiler as of 2.2.20, not a workaround for a
  build-tool quirk — expect it to go away once Kotlin adds a `JVM_25` target.
- **First `make setup` is slow.** It builds swift-java from source (a large
  Apple project with its own Gradle+SwiftPM dependency graph) rather than
  pulling prebuilt artifacts, since none are published. Expect it to take
  several minutes and to need a real network connection; subsequent
  `make build`/`make run` calls don't repeat this work.
