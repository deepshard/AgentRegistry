// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NativeToken.sol";
import "./HardwareAttestation.sol";

contract AgentRegistry {
    SomeNativeToken public immutable someNativeToken;
    HardwareAttestation public immutable attestation;

    // Only store active stakes - essential for on-chain security
    mapping(address => mapping(address => uint256)) public stakes;

    event AgentRegistered(
        address indexed agentAddress,
        uint256 minStake,
        string metadataURI,
        bytes32 indexed serialNumber,
        uint256 timestamp,
        bytes32[] merkleProof,    // Include full verification data
        bytes rootSignature
    );

    event AgentDeactivated(
        address indexed agentAddress,
        uint256 timestamp
    );

    event StakeDeposited(
        address indexed agent,
        address indexed staker,
        uint256 amount,
        uint256 timestamp
    );

    event StakeWithdrawn(
        address indexed agent,
        address indexed staker,
        uint256 amount,
        uint256 timestamp
    );

    constructor(address _swarmToken, address _attestation) {
        someNativeToken = SomeNativeToken(_swarmToken);
        attestation = HardwareAttestation(_attestation);
    }

    function registerAgent(
        uint256 _minStake,
        string calldata _metadataURI,
        HardwareAttestation.VerificationProof calldata proof
    ) external {
        // Verify hardware directly
        require(attestation.verifyDevice(proof, msg.sender));

        // Emit comprehensive registration event
        emit AgentRegistered(
            msg.sender,
            _minStake,
            _metadataURI,
            proof.serialNumber,
            block.timestamp,
            proof.merkleProof,
            proof.rootSignature
        );
    }

    function stake(
        address agent, 
        uint256 amount
    ) external {
        // Transfer tokens first
        require(
            someNativeToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        
        // Update stake
        stakes[agent][msg.sender] = amount;
        
        // Emit stake event
        emit StakeDeposited(
            agent,
            msg.sender,
            amount,
            block.timestamp
        );
    }

    function unstake(address agent) external {
        uint256 amount = stakes[agent][msg.sender];
        require(amount > 0, "No stake found");

        // Clear stake before transfer
        stakes[agent][msg.sender] = 0;
        
        // Transfer tokens
        require(
            someNativeToken.transfer(msg.sender, amount),
            "Transfer failed"
        );

        // Emit withdrawal event
        emit StakeWithdrawn(
            agent,
            msg.sender,
            amount,
            block.timestamp
        );
    }

    // View function for current stakes - essential for on-chain operations
    function getStake(address agent, address staker) external view returns (uint256) {
        return stakes[agent][staker];
    }
}