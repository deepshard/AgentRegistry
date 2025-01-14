// test/AgentRegistry.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AgentRegistry.sol";
import "../src/HardwareAttestation.sol";
import "../src/NativeToken.sol";

contract AgentRegistryTest is Test {
    HardwareAttestation attestation;
    AgentRegistry registry;
    SomeNativeToken token;
    
    // Test data structure
    struct TestCase {
        address deviceAddress;
        bytes32 serialNumber;
        bytes32[] merkleProof;
        bytes rootSignature;
    }
    
    function setUp() public {
        // Load test data
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/testdata/hardware-attestation-tests.json");

        console.log(path);
        string memory json = vm.readFile(path);
        
        // Parse deployment data
        bytes32 merkleRoot = abi.decode(vm.parseJson(json, ".deployment.merkleRoot"), (bytes32));
        address rootKeyAddress = abi.decode(vm.parseJson(json, ".deployment.rootKeyAddress"), (address));
        
        // Deploy contracts
        token = new SomeNativeToken(address(this));
        attestation = new HardwareAttestation(merkleRoot, rootKeyAddress);
        registry = new AgentRegistry(address(token), address(attestation));
    }

    function testSerialCopyingAttack() public {
        // Load test data
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/testdata/hardware-attestation-tests.json");
        string memory json = vm.readFile(path);
        
        // Parse legitimate case
        TestCase memory legitimate;
        legitimate.deviceAddress = abi.decode(vm.parseJson(json, ".serialCopyingAttack.legitimateCase.address"), (address));
        legitimate.serialNumber = abi.decode(vm.parseJson(json, ".serialCopyingAttack.legitimateCase.serialNumber"), (bytes32));
        legitimate.merkleProof = abi.decode(vm.parseJson(json, ".serialCopyingAttack.legitimateCase.merkleProof"), (bytes32[]));
        legitimate.rootSignature = abi.decode(vm.parseJson(json, ".serialCopyingAttack.legitimateCase.rootSignature"), (bytes));
        
        // Parse attacker case
        TestCase memory attacker;
        attacker.deviceAddress = abi.decode(vm.parseJson(json, ".serialCopyingAttack.attackerCase.address"), (address));
        attacker.serialNumber = abi.decode(vm.parseJson(json, ".serialCopyingAttack.attackerCase.serialNumber"), (bytes32));
        attacker.merkleProof = abi.decode(vm.parseJson(json, ".serialCopyingAttack.attackerCase.merkleProof"), (bytes32[]));
        attacker.rootSignature = abi.decode(vm.parseJson(json, ".serialCopyingAttack.attackerCase.rootSignature"), (bytes));

        // First legitimate registration should work
        vm.prank(legitimate.deviceAddress);
        HardwareAttestation.VerificationProof memory legitimateProof = HardwareAttestation.VerificationProof({
            merkleProof: legitimate.merkleProof,
            serialNumber: legitimate.serialNumber,
            rootSignature: legitimate.rootSignature
        });
        registry.registerAgent(1 ether, "ipfs://legitimate", legitimateProof);

        // Attacker registration should fail
        vm.prank(attacker.deviceAddress);
        HardwareAttestation.VerificationProof memory attackerProof = HardwareAttestation.VerificationProof({
            merkleProof: attacker.merkleProof,
            serialNumber: attacker.serialNumber,
            rootSignature: attacker.rootSignature
        });
        vm.expectRevert("Serial already used");
        registry.registerAgent(1 ether, "ipfs://attacker", attackerProof);
    }

    function testWrongSigningKeyAttack() public {
        // Load test data
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/testdata/hardware-attestation-tests.json");
        string memory json = vm.readFile(path);
        
        // Parse attack case
        TestCase memory attacker;
        attacker.deviceAddress = abi.decode(vm.parseJson(json, ".wrongSigningKeyAttack.address"), (address));
        attacker.serialNumber = abi.decode(vm.parseJson(json, ".wrongSigningKeyAttack.serialNumber"), (bytes32));
        attacker.merkleProof = abi.decode(vm.parseJson(json, ".wrongSigningKeyAttack.merkleProof"), (bytes32[]));
        attacker.rootSignature = abi.decode(vm.parseJson(json, ".wrongSigningKeyAttack.rootSignature"), (bytes));

        // Attempt should fail
        vm.prank(attacker.deviceAddress);
        HardwareAttestation.VerificationProof memory proof = HardwareAttestation.VerificationProof({
            merkleProof: attacker.merkleProof,
            serialNumber: attacker.serialNumber,
            rootSignature: attacker.rootSignature
        });
        vm.expectRevert("Invalid signature");
        registry.registerAgent(1 ether, "ipfs://malicious", proof);
    }

    function testDoubleRegistration() public {
        string memory json = vm.readFile("./test/testdata/hardware-attestation-tests.json");
        
        TestCase memory registration = parseTestCase(json, ".doubleRegistrationAttack.firstRegistration");
        
        // First registration should succeed
        vm.prank(registration.deviceAddress);
        HardwareAttestation.VerificationProof memory proof = createProof(registration);
        registry.registerAgent(1 ether, "ipfs://first", proof);

        // Second registration should fail
        vm.prank(registration.deviceAddress);
        vm.expectRevert("Serial already used");
        registry.registerAgent(1 ether, "ipfs://second", proof);
    }

    function testInvalidMerklePath() public {
        string memory json = vm.readFile("./test/testdata/hardware-attestation-tests.json");
        
        TestCase memory attack = parseTestCase(json, ".invalidMerklePathAttack");
        
        vm.prank(attack.deviceAddress);
        HardwareAttestation.VerificationProof memory proof = createProof(attack);
        vm.expectRevert("Invalid serial number");
        registry.registerAgent(1 ether, "ipfs://invalid", proof);
    }

    function testSignatureReplay() public {
        string memory json = vm.readFile("./test/testdata/hardware-attestation-tests.json");
        
        TestCase memory legitimate = parseTestCase(json, ".signatureReplayAttack.legitimateCase");
        TestCase memory attack = parseTestCase(json, ".signatureReplayAttack.attackerCase");
        
        // First registration should succeed
        vm.prank(legitimate.deviceAddress);
        HardwareAttestation.VerificationProof memory legitimateProof = createProof(legitimate);
        registry.registerAgent(1 ether, "ipfs://legitimate", legitimateProof);

        // Replay attack should fail
        vm.prank(attack.deviceAddress);
        HardwareAttestation.VerificationProof memory attackProof = createProof(attack);
        vm.expectRevert("Invalid signature");
        registry.registerAgent(1 ether, "ipfs://replay", attackProof);
    }

    function testEmptyProof() public {
        string memory json = vm.readFile("./test/testdata/hardware-attestation-tests.json");
        
        TestCase memory attack = parseTestCase(json, ".emptyProofAttack");
        
        vm.prank(attack.deviceAddress);
        HardwareAttestation.VerificationProof memory proof = createProof(attack);
        vm.expectRevert("Invalid serial number");  // You might need to add this check to the contract
        registry.registerAgent(1 ether, "ipfs://empty", proof);
    }

    // Helper function to parse test cases
    function parseTestCase(string memory json, string memory path) internal returns (TestCase memory test) {
        test.deviceAddress = abi.decode(vm.parseJson(json, string.concat(path, ".address")), (address));
        test.serialNumber = abi.decode(vm.parseJson(json, string.concat(path, ".serialNumber")), (bytes32));
        test.merkleProof = abi.decode(vm.parseJson(json, string.concat(path, ".merkleProof")), (bytes32[]));
        test.rootSignature = abi.decode(vm.parseJson(json, string.concat(path, ".rootSignature")), (bytes));
        return test;
    }

    // Helper function to create proof struct
    function createProof(TestCase memory test) internal pure returns (HardwareAttestation.VerificationProof memory) {
        return HardwareAttestation.VerificationProof({
            merkleProof: test.merkleProof,
            serialNumber: test.serialNumber,
            rootSignature: test.rootSignature
        });
    }
}