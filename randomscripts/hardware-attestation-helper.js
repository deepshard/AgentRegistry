const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const { ethers } = require('ethers');

class HardwareAttestationHelper {
    constructor(serialNumbers) {
        // First create the hashes that will be used as serialNumbers in the contract
        const serialHashes = serialNumbers.map(serial => 
            ethers.keccak256(ethers.toUtf8Bytes(serial))
        );
        
        // Debug: Print original serial hash
        console.log("Original Serial Hash:", serialHashes[0]);
        
        // Create leaves exactly as the contract does
        const values = serialHashes.map(hash => {
            return [hash];
        });
        
        this.tree = StandardMerkleTree.of(values, ["bytes32"]);
    }

    getMerkleRoot() {
        return this.tree.root;
    }

    getProof(serialHash) {
        for (const [i, v] of this.tree.entries()) {
            if (v[0] === serialHash) {
                console.log("LEAF: ", this.tree.leafHash(v))
                return this.tree.getProof(i);
            }
        }
        throw new Error('Serial number not found');
    }

    async generateVerificationProof(serialHash, signingKey, deviceAddress) {
        const proof = this.getProof(serialHash);
        
        // Pack the message without hashing
        const messageHash = ethers.keccak256(
            ethers.solidityPacked(
                ['address', 'bytes32'],
                [deviceAddress, serialHash]
            )
        );
        
        // Then sign the hash
        const signature = await signingKey.signMessage(ethers.getBytes(messageHash));
        
        return {
            merkleProof: proof,
            serialNumber: serialHash,
            rootSignature: signature
        };
    }
}

module.exports = HardwareAttestationHelper;