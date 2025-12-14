class TrieNode:
    def __init__(self):
        self.children = {}
        self.patients = []  # List of full patient dictionaries

class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, key, patient):
        if not key:
            return
        node = self.root
        for char in key.lower():
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.patients.append(patient)

    def search(self, prefix):
        node = self.root
        for char in prefix.lower():
            if char not in node.children:
                return []
            node = node.children[char]
        
        # Perform DFS to find all patients in the subtree
        return self._dfs(node)

    def _dfs(self, node):
        results = []
        # Add patients at the current node
        results.extend(node.patients)
        
        # Recursively visit children
        for char in node.children:
            results.extend(self._dfs(node.children[char]))
            
        return results

    def clear(self):
        self.root = TrieNode()
