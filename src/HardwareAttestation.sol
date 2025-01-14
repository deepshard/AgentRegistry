// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Add this import
import "forge-std/console.sol";

contract HardwareAttestation is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    bytes32 public validSerialNumbersRoot;
    address public rootSigningKey;
    
    mapping(bytes32 => bool) public usedSerialNumbers;
    
    struct VerificationProof {
        bytes32[] merkleProof;
        bytes32 serialNumber;
        bytes rootSignature;
    }

    event RootUpdated(bytes32 newRoot);
    event SigningKeyUpdated(address newKey);
    event DeviceVerified(address indexed deviceAddress, bytes32 indexed serialNumber);

    constructor(bytes32 initialRoot, address initialSigningKey) Ownable(msg.sender) {
        validSerialNumbersRoot = initialRoot;
        rootSigningKey = initialSigningKey;
        emit RootUpdated(initialRoot);
        emit SigningKeyUpdated(initialSigningKey);
    }

    function updateRoot(bytes32 newRoot) external onlyOwner {
        validSerialNumbersRoot = newRoot;
        emit RootUpdated(newRoot);
    }

    function updateSigningKey(address newKey) external onlyOwner {
        rootSigningKey = newKey;
        emit SigningKeyUpdated(newKey);
    }

    function verifyDevice(VerificationProof calldata proof, address deviceAddress) external returns (bool) {
        require(!usedSerialNumbers[proof.serialNumber], "Serial already used");

        console.log(deviceAddress);
        
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(proof.serialNumber))));
        require(
            MerkleProof.verify(proof.merkleProof, validSerialNumbersRoot, leaf),
            "Invalid serial number"
        );
        
        // Use deviceAddress parameter instead of msg.sender
        bytes32 message = keccak256(abi.encodePacked(deviceAddress, proof.serialNumber));
        bytes32 ethSignedMessageHash = message.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(proof.rootSignature);

        console.log(signer);
        
        require(signer == rootSigningKey, "Invalid signature");
        
        usedSerialNumbers[proof.serialNumber] = true;
        
        emit DeviceVerified(deviceAddress, proof.serialNumber);
        return true;
    }

    function isSerialUsed(bytes32 serialNumber) external view returns (bool) {
        return usedSerialNumbers[serialNumber];
    }
}