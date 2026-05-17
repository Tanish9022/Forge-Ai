import unittest
import json
import time
from ledger import Blockchain, Block

class TestBlockchain(unittest.TestCase):
    def setUp(self):
        self.blockchain = Blockchain()

    def test_genesis_block(self):
        self.assertEqual(len(self.blockchain.chain), 1)
        self.assertEqual(self.blockchain.chain[0].data["report"], "GENESIS_BLOCK")

    def test_add_block(self):
        data = {"test": "data"}
        self.blockchain.create_block(data)
        self.assertEqual(len(self.blockchain.chain), 2)
        self.assertEqual(self.blockchain.chain[1].data, data)
        self.assertEqual(self.blockchain.chain[1].previous_hash, self.blockchain.chain[0].hash)

    def test_verify_integrity_valid(self):
        self.blockchain.create_block({"test": "data 1"})
        self.blockchain.create_block({"test": "data 2"})
        self.assertTrue(self.blockchain.verify_chain_integrity())

    def test_verify_integrity_tampered_data(self):
        self.blockchain.create_block({"test": "data 1"})
        # Tamper with the data
        self.blockchain.chain[1].data = {"test": "tampered"}
        # Integrity check should fail because hash won't match
        self.assertFalse(self.blockchain.verify_chain_integrity())

    def test_verify_integrity_tampered_hash(self):
        self.blockchain.create_block({"test": "data 1"})
        # Tamper with the hash
        self.blockchain.chain[1].hash = "fake_hash"
        self.assertFalse(self.blockchain.verify_chain_integrity())

if __name__ == '__main__':
    unittest.main()
