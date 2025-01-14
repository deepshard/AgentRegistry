// security-test-cases.js
const fs = require('fs');
const path = require('path');
const HardwareAttestationHelper = require('./hardware-attestation-helper');
const { ethers } = require('ethers');

async function generateTestCases() {
    const validRootKey = new ethers.Wallet("0x1234567890123456789012345678901234567890123456789012345678901234");
    const maliciousRootKey = new ethers.Wallet("0x2234567890123456789012345678901234567890123456789012345678901234");
    
    const validSerials = [
        'SERIAL001',
        'SERIAL002',
        'SERIAL003'
    ];
    
    const helper = new HardwareAttestationHelper(validSerials);
    const merkleRoot = helper.getMerkleRoot();
    
    const testCases = {
        deployment: {
            merkleRoot,
            rootKeyAddress: validRootKey.address
        }
    };

    // 1. Serial Number Copying Attack (existing)
    const legitimateAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const attackerAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
    const serialHash1 = ethers.keccak256(ethers.toUtf8Bytes('SERIAL001'));
    
    const legitimateProof1 = await helper.generateVerificationProof(
        serialHash1,
        validRootKey,
        legitimateAddress
    );
    
    const attackerProof = await helper.generateVerificationProof(
        serialHash1,
        validRootKey,
        attackerAddress
    );
    
    testCases.serialCopyingAttack = {
        legitimateCase: {
            address: legitimateAddress,
            serialNumber: serialHash1,
            merkleProof: legitimateProof1.merkleProof,
            rootSignature: legitimateProof1.rootSignature
        },
        attackerCase: {
            address: attackerAddress,
            serialNumber: serialHash1,
            merkleProof: attackerProof.merkleProof,
            rootSignature: attackerProof.rootSignature
        }
    };

    // 2. Wrong Signing Key Attack (existing)
    const maliciousProof = await helper.generateVerificationProof(
        ethers.keccak256(ethers.toUtf8Bytes('SERIAL002')),
        maliciousRootKey,
        legitimateAddress
    );
    
    testCases.wrongSigningKeyAttack = {
        address: legitimateAddress,
        serialNumber: ethers.keccak256(ethers.toUtf8Bytes('SERIAL002')),
        merkleProof: maliciousProof.merkleProof,
        rootSignature: maliciousProof.rootSignature
    };

    // 3. Double Registration Attack
    const serialHash2 = ethers.keccak256(ethers.toUtf8Bytes('SERIAL002'));
    const legitimateProof2 = await helper.generateVerificationProof(
        serialHash2,
        validRootKey,
        legitimateAddress
    );

    testCases.doubleRegistrationAttack = {
        firstRegistration: {
            address: legitimateAddress,
            serialNumber: serialHash2,
            merkleProof: legitimateProof2.merkleProof,
            rootSignature: legitimateProof2.rootSignature
        },
        secondRegistration: {
            address: legitimateAddress,
            serialNumber: serialHash2,
            merkleProof: legitimateProof2.merkleProof,
            rootSignature: legitimateProof2.rootSignature
        }
    };

    // 4. Invalid Merkle Path Attack
    testCases.invalidMerklePathAttack = {
        address: legitimateAddress,
        serialNumber: serialHash1,
        merkleProof: legitimateProof2.merkleProof,  // Proof from different serial
        rootSignature: legitimateProof1.rootSignature
    };

    // 5. Zero Address Attack
    const zeroAddress = "0x0000000000000000000000000000000000000000";
    const zeroAddressProof = await helper.generateVerificationProof(
        serialHash1,
        validRootKey,
        zeroAddress
    );

    testCases.zeroAddressAttack = {
        address: zeroAddress,
        serialNumber: serialHash1,
        merkleProof: zeroAddressProof.merkleProof,
        rootSignature: zeroAddressProof.rootSignature
    };

    // 6. Signature Replay Attack
    testCases.signatureReplayAttack = {
        legitimateCase: {
            address: legitimateAddress,
            serialNumber: serialHash1,
            merkleProof: legitimateProof1.merkleProof,
            rootSignature: legitimateProof1.rootSignature
        },
        attackerCase: {
            address: legitimateAddress,
            serialNumber: serialHash2,  // Different serial
            merkleProof: legitimateProof2.merkleProof,
            rootSignature: legitimateProof1.rootSignature  // Reused signature
        }
    };

    // 7. Empty Proof Attack
    testCases.emptyProofAttack = {
        address: legitimateAddress,
        serialNumber: serialHash1,
        merkleProof: [],  // Empty proof
        rootSignature: legitimateProof1.rootSignature
    };

    // Save test cases to JSON file
    const testDataPath = path.join(__dirname, '..', 'test', 'testdata', 'hardware-attestation-tests.json');
    fs.writeFileSync(
        testDataPath,
        JSON.stringify(testCases, null, 2)
    );
    
    console.log('Test cases generated and saved to:', testDataPath);
}

generateTestCases().catch(console.error);