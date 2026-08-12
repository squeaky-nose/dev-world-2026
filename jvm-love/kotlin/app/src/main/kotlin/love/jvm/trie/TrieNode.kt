package love.jvm.trie

/**
 * Plays two roles at once: a trie node (`isEndOfWord`, `childrenRoot`) and an
 * element inside its *parent's* children-AVL-tree (`char`, `left`, `right`,
 * `height`). AVL balancing applies only to sibling sets at a given depth, not
 * to trie depth itself. See [AvlTrie] for insert/contains and the rebalancing
 * logic that operates on these nodes.
 */
internal class TrieNode(val char: Char) {
    var isEndOfWord: Boolean = false
    var childrenRoot: TrieNode? = null

    var left: TrieNode? = null
    var right: TrieNode? = null
    var height: Int = 1
}
