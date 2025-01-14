// script/Deploy.s.sol
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgentRegistry.sol";
import "../src/NativeToken.sol";
import "../src/HardwareAttestation.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Initial merkle root and root key for hardware attestation
        bytes32 initialMerkleRoot = 0xf5a973d438ee12875283b41e1f59fe855ea891b08f909241fdf5cefd0938ab74; // Example value
        address rootKey = 0x2e988A386a799F506693793c6A5AF6B54dfAaBfB; // Example value

        // Deploy contracts
        SomeNativeToken token = new SomeNativeToken(msg.sender);
        HardwareAttestation attestation = new HardwareAttestation(
            initialMerkleRoot,
            rootKey
        );
        AgentRegistry registry = new AgentRegistry(
            address(token),
            address(attestation)
        );

        vm.stopBroadcast();
    }
}