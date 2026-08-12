# jvm-love

A command-line app that builds the same word list into two independent,
from-scratch **self-balancing trie** implementations — one native Kotlin, one
native Swift — inside a *single JVM process*, then lets you look up words and
compares both backends side by side.

```
$ make run
Kotlin trie:  235976 words in 60.47 ms
Swift trie:   235976 words in 571.89 ms

Enter words to look up (Ctrl-D to quit):
  "aardvark":
    Kotlin: found     (3.542 us)
    Swift:  found     (outer 3924.750 us, inner 4.417 us)
    Kotlin is faster than Swift by 0.875 us (19.8%)
    FFM overhead: 3920.333 us (99.9% of the Swift call)
  "zebra":
    Kotlin: found     (8.125 us)
    Swift:  found     (outer 55.750 us, inner 7.750 us)
    Swift is faster than Kotlin by 0.375 us (4.6%)
    FFM overhead: 48.000 us (86.1% of the Swift call)
```

Each lookup prints four lines:
1. **Kotlin** — the result, timed with `measureNanoTime` around
   `AvlTrie.contains`.
2. **Swift** — the result, timed two ways: **outer** is `measureNanoTime`
   around the whole call from Kotlin (includes FFM downcall/marshalling
   cost); **inner** is `LookupResult.lookupTimeMillis`, timed *inside* Swift
   with `ContinuousClock`, covering only the trie walk itself.
   `SwiftAVLTrie.contains` returns this alongside the boolean result (a
   `LookupResult` struct) rather than exposing it through a separate
   stateful accessor call.
3. **Speed comparison** — Kotlin's time vs. Swift's *inner* time (the
   apples-to-apples comparison: both are pure trie-walk time, with no FFM
   crossing in either figure), reporting which was faster and by how much,
   in both µs and relative %.
4. **FFM overhead** — `outer - inner`: what crossing the JVM/native boundary
   actually costs, as µs and as a percentage of the whole Swift call. Note
   the first lookup above (~3.9 ms overhead, 99.9% of the call) versus a
   later one (tens of µs, ~86%) — the FFM downcall stub pays a one-time
   warmup cost on its first invocation.

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
│   ├── Main.kt                 builds both tries, runs the stdin lookup loop
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

### Case sensitivity

Both tries lowercase every word — on insertion (`AvlTrie.insert` /
`SwiftAVLTrie.insert`) and on lookup (`AvlTrie.contains` /
`SwiftAVLTrie.lookup`) — so `"Zebra"`, `"ZEBRA"`, and `"zebra"` all hit the
same node. One visible effect: building from `/usr/share/dict/words` (which
contains both `"Aardvark"` and `"aardvark"` as separate lines for some
words) now reports a slightly *lower* word count than the raw line count,
since case-variant duplicates collapse into one trie entry.

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

`/usr/share/dict/words` (present by default on macOS) is used as the
default word list — no separate download needed.

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
make run      # build (if needed) and run interactively against /usr/share/dict/words
```

Run `make` (or `make help`) to list all available targets. Use a different
word list with:

```
make run WORDS=/path/to/your/wordlist.txt
```

The word list format is one word per line (blank lines are skipped); this is
exactly the format `/usr/share/dict/words` is already in.

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
  interactive word-lookup loop when input is piped in (`make run` needs this
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
