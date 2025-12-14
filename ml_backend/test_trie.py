import unittest
from trie import Trie

class TestTrie(unittest.TestCase):
    def setUp(self):
        self.trie = Trie()
        self.patient1 = {'id': 'P1', 'name': 'John Doe'}
        self.patient2 = {'id': 'P2', 'name': 'Jane Doe'}
        
    def test_insert_and_search(self):
        self.trie.insert('john', self.patient1)
        results = self.trie.search('jo')
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['name'], 'John Doe')
        
    def test_dfs_traversal(self):
        self.trie.insert('j', self.patient1)
        self.trie.insert('ja', self.patient2)
        
        # Searching 'j' should return both John and Jane (DFS)
        results = self.trie.search('j')
        names = [p['name'] for p in results]
        self.assertIn('John Doe', names)
        self.assertIn('Jane Doe', names)
        
    def test_no_match(self):
        self.trie.insert('john', self.patient1)
        results = self.trie.search('xyz')
        self.assertEqual(results, [])

if __name__ == '__main__':
    unittest.main()
