//
//  AVLScrabbleTrie.swift
//  jvm-love
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

/// A trie (prefix tree) whose children at every node are stored in their own
/// AVL-balanced binary search tree keyed by character, instead of a flat
/// array/dictionary. This bounds child lookup at each node to O(log k),
/// where k is the number of distinct children that node currently has,
/// instead of an unbalanced BST's worst-case O(k).
///
/// Every `Node` plays two roles at once: it is a trie node (`isEndOfWord`,
/// `childrenRoot`) and it is also an element inside its *parent's*
/// children-AVL-tree (`character`, `left`, `right`, `height`). The AVL
/// balancing applies only to sibling sets, not to trie depth.
final class Node {
    let character: Character
    var isEndOfWord = false
    var childrenRoot: Node?

    var left: Node?
    var right: Node?
    var height = 1

    /// Creates a leaf node holding `character`, with no children in either role (trie child or AVL sibling).
    init(character: Character) {
        self.character = character
    }
}

/// Height of `node`'s subtree in the sibling AVL tree; a missing (nil) child counts as height 0.
private func height(_ node: Node?) -> Int {
    node?.height ?? 0
}

/// Recomputes `node`'s cached height from its two children -- must run bottom-up after any structural change.
private func updateHeight(_ node: Node) {
    node.height = 1 + max(height(node.left), height(node.right))
}

/// AVL balance factor: left subtree height minus right. Magnitude > 1 means `node` needs rebalancing.
private func balanceFactor(_ node: Node) -> Int {
    height(node.left) - height(node.right)
}

/// Standard AVL right rotation: promotes `y`'s left child to `y`'s position, fixing a left-heavy imbalance.
private func rotateRight(_ y: Node) -> Node {
    let x = y.left!
    y.left = x.right
    x.right = y
    updateHeight(y)
    updateHeight(x)
    return x
}

/// Standard AVL left rotation: promotes `x`'s right child to `x`'s position, fixing a right-heavy imbalance.
private func rotateLeft(_ x: Node) -> Node {
    let y = x.right!
    x.right = y.left
    y.left = x
    updateHeight(x)
    updateHeight(y)
    return y
}

/// Restores the AVL invariant at `node` after an insert, returning the (possibly
/// new) subtree root. A balance factor outside [-1, 1] means one side is at
/// least two levels deeper than the other and needs a rotation to fix.
private func rebalance(_ node: Node) -> Node {
    let balance = balanceFactor(node) // >1 = left-heavy, <-1 = right-heavy, else already balanced

    if balance > 1 {
        // Left-Right case: the left child itself leans right, so straightening it
        // with a left rotation first turns this into a plain Left-Left case.
        if balanceFactor(node.left!) < 0 {
            node.left = rotateLeft(node.left!)
        }
        return rotateRight(node)
    }

    if balance < -1 {
        // Right-Left case: mirror image of the above -- straighten the right
        // child with a right rotation first, then a plain Right-Right rotation fixes it.
        if balanceFactor(node.right!) > 0 {
            node.right = rotateRight(node.right!)
        }
        return rotateLeft(node)
    }

    return node
}

/// Create-if-absent insert of `character` among `root`'s siblings, rebalancing
/// the sibling AVL tree as needed. If `character` already exists among the
/// siblings, the existing node is returned untouched (no height update, no
/// rotation) -- this is what lets shared prefixes reuse structure, and keeps
/// re-walking an already-inserted prefix O(depth) with zero rotation cost.
private func avlInsert(_ root: Node?, _ character: Character) -> Node {
    guard let root else {
        return Node(character: character)
    }

    if character < root.character {
        root.left = avlInsert(root.left, character)
    } else if character > root.character {
        root.right = avlInsert(root.right, character)
    } else {
        return root
    }

    updateHeight(root)
    return rebalance(root)
}

/// Iterative BST lookup of `character` among `root`'s siblings; O(log k) thanks to the AVL balance.
private func avlFind(_ root: Node?, _ character: Character) -> Node? {
    var current = root
    while let node = current {
        if character < node.character {
            current = node.left
        } else if character > node.character {
            current = node.right
        } else {
            return node
        }
    }
    return nil
}

extension Node {
    /// In-order walk of this node's children-AVL-tree, yielding every child actually present.
    func children() -> [Node] {
        var result: [Node] = []
        func visit(_ node: Node?) {
            guard let node else { return }
            visit(node.left)
            result.append(node)
            visit(node.right)
        }
        visit(childrenRoot)
        return result
    }
}

/// Standard English Scrabble letter point values.
private let letterValues: [Character: Int] = [
    "a": 1, "e": 1, "i": 1, "o": 1, "u": 1, "l": 1, "n": 1, "s": 1, "t": 1, "r": 1,
    "d": 2, "g": 2,
    "b": 3, "c": 3, "m": 3, "p": 3,
    "f": 4, "h": 4, "v": 4, "w": 4, "y": 4,
    "k": 5,
    "j": 8, "x": 8,
    "q": 10, "z": 10,
]

/// Sum of `word`'s letter values under standard English Scrabble scoring.
func scrabbleScore(_ word: String) -> Int {
    word.reduce(0) { $0 + (letterValues[$1] ?? 0) }
}

/// One character position in a wildcard pattern.
enum Token {
    /// Matches exactly this letter -- a tile already fixed on the board, not drawn from the rack.
    case literal(Character)
    /// Matches exactly one wildcard letter, drawn from the rack.
    case single
    /// Matches one or more consecutive wildcard letters, all drawn from the rack.
    case multi
}

/// Splits `pattern` into per-character `Token`s: `_` and `*` become wildcards, everything else a lowercased literal.
func tokenize(_ pattern: String) -> [Token] {
    pattern.map { char in
        switch char {
        case "_": return .single
        case "*": return .multi
        default: return .literal(Character(char.lowercased()))
        }
    }
}

/// Backtracking match of `tokens` against the trie, starting at `node` and
/// `tokenIndex`. A literal token follows its one matching child; `.single`
/// branches into every child currently affordable from `rack`; `.multi`
/// delegates to `matchMulti`. A full match requires the token sequence to be
/// exhausted exactly at a node with `isEndOfWord` -- an anchored, whole-word
/// match, not a prefix search. `seen` de-dupes: when two wildcard tokens sit
/// adjacent with no literal anchor between them, the same word is reachable
/// via more than one split point.
private func matchExact(
    _ node: Node,
    _ tokens: [Token],
    _ tokenIndex: Int,
    _ rack: inout [Character: Int],
    _ wordSoFar: String,
    _ seen: inout Set<String>,
    _ results: inout [String]
) {
    if tokenIndex == tokens.count {
        if node.isEndOfWord, seen.insert(wordSoFar).inserted {
            results.append(wordSoFar)
        }
        return
    }
    switch tokens[tokenIndex] {
    case .literal(let char):
        guard let child = avlFind(node.childrenRoot, char) else { return }
        matchExact(child, tokens, tokenIndex + 1, &rack, wordSoFar + String(char), &seen, &results)
    case .single:
        for child in node.children() {
            let remaining = rack[child.character] ?? 0 // how many of this letter the rack has left
            if remaining > 0 {
                rack[child.character] = remaining - 1 // consume one for this branch of the search
                matchExact(child, tokens, tokenIndex + 1, &rack, wordSoFar + String(child.character), &seen, &results)
                rack[child.character] = remaining // restore it before trying the next sibling child
            }
        }
    case .multi:
        matchMulti(node, tokens, tokenIndex, &rack, wordSoFar, &seen, &results)
    }
}

/// Consumes one or more characters under the `*` token at `tokenIndex`. Each
/// child affordable from `rack` is tried both ways -- stop the `*` here and
/// advance to the next token (via `matchExact`), or keep consuming more
/// under this same `*` -- so every valid split point is explored.
private func matchMulti(
    _ node: Node,
    _ tokens: [Token],
    _ tokenIndex: Int,
    _ rack: inout [Character: Int],
    _ wordSoFar: String,
    _ seen: inout Set<String>,
    _ results: inout [String]
) {
    for child in node.children() {
        let remaining = rack[child.character] ?? 0 // how many of this letter the rack has left
        if remaining > 0 {
            rack[child.character] = remaining - 1 // consume one letter to extend the `*` span by this child
            matchExact(child, tokens, tokenIndex + 1, &rack, wordSoFar + String(child.character), &seen, &results) // try stopping `*` here
            matchMulti(child, tokens, tokenIndex, &rack, wordSoFar + String(child.character), &seen, &results) // try consuming further
            rack[child.character] = remaining // restore before trying the next sibling child
        }
    }
}

/// Result of a `SwiftAVLScrabbleTrie.findExactMatches` search: the matched words
/// plus how long the search itself took, measured inside Swift with
/// `ContinuousClock` -- i.e. excluding the FFM downcall/marshalling overhead
/// a caller's own timer around the whole call would include. Models the
/// word list as indexed getters (`wordCount()`/`word(at:)`) rather than
/// returning a Swift `Array` directly -- jextract's FFM mode does not support
/// extracting collection-typed return values, only scalars/strings/nominal
/// types with scalar/string members.
public final class WordSearchResult {
    private let words: [String]
    private let timeMillis: Double

    /// Wraps an already-scored-and-sorted `words` list together with the search's own `searchTimeMillis`.
    init(words: [String], searchTimeMillis: Double) {
        self.words = words
        self.timeMillis = searchTimeMillis
    }

    /// Number of matched words -- paired with `word(at:)` since jextract's FFM
    /// mode can't extract a Swift `Array` return value directly.
    public func wordCount() -> Int {
        words.count
    }

    /// The matched word at `index` (0..<wordCount()); the indexed-getter workaround described on the type.
    public func word(at index: Int) -> String {
        words[index]
    }

    /// How long the search itself took, in milliseconds, measured inside Swift with `ContinuousClock`.
    public func searchTimeMillis() -> Double {
        timeMillis
    }
}

/// The Swift half of the two independent "self-balancing trie" demos in this
/// project (see the Kotlin `AvlScrabbleTrie` for the JVM-native counterpart). Invoked
/// from the Kotlin app in-process via swift-java's jextract FFM bindings --
/// this class never runs as a separate OS process.
public final class SwiftAVLScrabbleTrie {
    private let root = Node(character: "\0")
    private let clock = ContinuousClock()
    private var insertedCount = 0
    private var lastBuildTimeMillis: Double = 0

    /// Creates an empty trie, ready for `buildFromFile`. Exposed as the jextract-generated
    /// entry point the Kotlin side calls to construct the Swift trie in-process.
    public init() {}

    /// Inserts `word` into the trie, lowercasing it first so lookups are
    /// case-insensitive (see README's "Case sensitivity" section). Walks one
    /// character at a time, growing each node's sibling AVL tree as needed,
    /// and only increments `insertedCount` the first time a given word is
    /// marked as ending here (a duplicate insert is a no-op count-wise).
    private func insert(_ word: Substring) {
        guard !word.isEmpty else { return }
        var node = root
        for character in word.lowercased() {
            node.childrenRoot = avlInsert(node.childrenRoot, character)
            node = avlFind(node.childrenRoot, character)!
        }
        if !node.isEndOfWord {
            node.isEndOfWord = true
            insertedCount += 1
        }
    }

    /// Reads `path` itself (no word list crosses the Java/Swift interop
    /// boundary -- only the file path does) and builds the trie natively.
    public func buildFromFile(_ path: String) {
        let start = Date()
        insertedCount = 0

        guard let data = FileManager.default.contents(atPath: path),
            let contents = String(data: data, encoding: .utf8)
        else {
            fatalError("SwiftAVLScrabbleTrie.buildFromFile: could not read \(path)")
        }

        for line in contents.split(separator: "\n", omittingEmptySubsequences: true) {
            let word = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !word.isEmpty {
                insert(Substring(word))
            }
        }

        lastBuildTimeMillis = Date().timeIntervalSince(start) * 1000
    }

    /// Dictionary words that fully match `pattern` end-to-end -- literal
    /// characters match exactly, `_` matches exactly one wildcard letter and
    /// `*` matches one or more, every wildcard letter drawn from `rack`
    /// (each rack letter usable at most once per candidate word). An
    /// all-literal pattern with an empty rack degenerates to a plain
    /// membership check. Sorted by `scrabbleScore`, highest first. Times
    /// only the search itself, natively, using `ContinuousClock` -- see
    /// `WordSearchResult`.
    public func findExactMatches(_ pattern: String, _ rack: String) -> WordSearchResult {
        let start = clock.now // marks the "inner" timing window -- pure search time, no FFM crossing included
        let tokens = tokenize(pattern)
        var rackCounts: [Character: Int] = [:]
        for char in rack.lowercased() { rackCounts[char, default: 0] += 1 }
        var seen: Set<String> = []
        var results: [String] = []
        if !tokens.isEmpty {
            matchExact(root, tokens, 0, &rackCounts, "", &seen, &results)
        }
        results.sort { scrabbleScore($0) > scrabbleScore($1) }
        return WordSearchResult(words: results, searchTimeMillis: millis(since: start))
    }

    /// Converts a `ContinuousClock` elapsed duration (seconds + attoseconds) since `start` into milliseconds.
    private func millis(since start: ContinuousClock.Instant) -> Double {
        let components = (clock.now - start).components // (seconds, attoseconds) -- ContinuousClock's native precision
        return Double(components.seconds) * 1000 + Double(components.attoseconds) / 1_000_000_000_000_000
    }

    /// Number of distinct words inserted so far (duplicates don't double-count).
    public func wordCount() -> Int {
        insertedCount
    }

    /// How long the most recent `buildFromFile` call took to build the trie, in milliseconds.
    public func buildTimeMillis() -> Double {
        lastBuildTimeMillis
    }
}
