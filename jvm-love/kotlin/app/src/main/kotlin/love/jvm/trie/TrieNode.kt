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

/** In-order walk of this node's children-AVL-tree, yielding every child actually present. */
internal fun TrieNode.children(): List<TrieNode> {
    val result = mutableListOf<TrieNode>()
    fun visit(node: TrieNode?) {
        if (node == null) return
        visit(node.left)
        result.add(node)
        visit(node.right)
    }
    visit(childrenRoot)
    return result
}
