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

    init(character: Character) {
        self.character = character
    }
}

private func height(_ node: Node?) -> Int {
    node?.height ?? 0
}

private func updateHeight(_ node: Node) {
    node.height = 1 + max(height(node.left), height(node.right))
}

private func balanceFactor(_ node: Node) -> Int {
    height(node.left) - height(node.right)
}

private func rotateRight(_ y: Node) -> Node {
    let x = y.left!
    y.left = x.right
    x.right = y
    updateHeight(y)
    updateHeight(x)
    return x
}

private func rotateLeft(_ x: Node) -> Node {
    let y = x.right!
    x.right = y.left
    y.left = x
    updateHeight(x)
    updateHeight(y)
    return y
}

private func rebalance(_ node: Node) -> Node {
    let balance = balanceFactor(node)

    if balance > 1 {
        if balanceFactor(node.left!) < 0 {
            node.left = rotateLeft(node.left!)
        }
        return rotateRight(node)
    }

    if balance < -1 {
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

/// Result of a single `SwiftAVLTrie.contains` lookup: whether the word was
/// found, plus how long the lookup itself took, measured inside Swift with
/// `ContinuousClock` -- i.e. excluding the FFM downcall/marshalling overhead
/// that a caller's own timer around the whole call would include.
public struct LookupResult {
    public let found: Bool
    public let lookupTimeMillis: Double
}

/// The Swift half of the two independent "self-balancing trie" demos in this
/// project (see the Kotlin `AvlTrie` for the JVM-native counterpart). Invoked
/// from the Kotlin app in-process via swift-java's jextract FFM bindings --
/// this class never runs as a separate OS process.
public final class SwiftAVLTrie {
    private let root = Node(character: "\0")
    private let clock = ContinuousClock()
    private var insertedCount = 0
    private var lastBuildTimeMillis: Double = 0

    public init() {}

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
            fatalError("SwiftAVLTrie.buildFromFile: could not read \(path)")
        }

        for line in contents.split(separator: "\n", omittingEmptySubsequences: true) {
            let word = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !word.isEmpty {
                insert(Substring(word))
            }
        }

        lastBuildTimeMillis = Date().timeIntervalSince(start) * 1000
    }

    /// Times only the lookup walk itself, natively in Swift, using
    /// `ContinuousClock` for nanosecond-scale resolution (`Date` is too
    /// coarse at the microsecond scale these lookups run at). Callers can
    /// compare `LookupResult.lookupTimeMillis` against their own wall-clock
    /// measurement of the call into `contains` to see the FFM crossing's
    /// overhead.
    public func contains(_ word: String) -> LookupResult {
        let start = clock.now
        let found = lookup(word)
        return LookupResult(found: found, lookupTimeMillis: millis(since: start))
    }

    private func lookup(_ word: String) -> Bool {
        var node = root
        for character in word.lowercased() {
            guard let next = avlFind(node.childrenRoot, character) else {
                return false
            }
            node = next
        }
        return node.isEndOfWord
    }

    private func millis(since start: ContinuousClock.Instant) -> Double {
        let components = (clock.now - start).components
        return Double(components.seconds) * 1000 + Double(components.attoseconds) / 1_000_000_000_000_000
    }

    public func wordCount() -> Int {
        insertedCount
    }

    public func buildTimeMillis() -> Double {
        lastBuildTimeMillis
    }
}
