import hashlib
import time
import json

class Block:
    def __init__(self, index, timestamp, data, previous_hash, hash):
        self.index = index
        self.timestamp = timestamp
        self.data = data
        self.previous_hash = previous_hash
        self.hash = hash

class Blockchain:
    def __init__(self):
        self.chain = []
        self.create_genesis_block()

    def create_genesis_block(self):
        """Creates the first block in the chain."""
        timestamp = time.time()
        data = {"report": "GENESIS_BLOCK", "action": "INIT", "score": 0.0}
        genesis_hash = self.calculate_hash(0, timestamp, data, "0")
        self.chain.append(Block(0, timestamp, data, "0", genesis_hash))

    @staticmethod
    def calculate_hash(index, timestamp, data, previous_hash):
        """Calculates the SHA-256 hash of a block."""
        block_string = json.dumps({
            "index": index,
            "timestamp": timestamp,
            "data": data,
            "previous_hash": previous_hash
        }, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()

    def create_block(self, data):
        """Creates a new block and adds it to the chain."""
        previous_block = self.chain[-1]
        index = previous_block.index + 1
        timestamp = time.time()
        previous_hash = previous_block.hash
        hash = self.calculate_hash(index, timestamp, data, previous_hash)
        
        new_block = Block(index, timestamp, data, previous_hash, hash)
        self.chain.append(new_block)
        return new_block

    def get_chain(self):
        """Returns the full chain as a list of dictionaries."""
        chain_data = []
        for block in self.chain:
            chain_data.append({
                "index": block.index,
                "timestamp": block.timestamp,
                "data": block.data,
                "previous_hash": block.previous_hash,
                "hash": block.hash
            })
        return chain_data

    def verify_chain_integrity(self):
        """Verifies the hashes of the entire chain."""
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i - 1]

            # Check if the stored hash matches the calculated hash
            if current_block.hash != self.calculate_hash(
                current_block.index,
                current_block.timestamp,
                current_block.data,
                current_block.previous_hash
            ):
                return False

            # Check if the previous_hash stored in current block matches the actual hash of previous block
            if current_block.previous_hash != previous_block.hash:
                return False

        return True
