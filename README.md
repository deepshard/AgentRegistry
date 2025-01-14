# Agent Registry Protocol

A decentralized protocol for rebuilding the AppStore on EVM, enabling secure agent-to-agent interactions with hardware-backed sybil resistance.

## Overview

The Agent Registry Protocol is designed to create a decentralized marketplace for AI agents, similar to the AppStore, but with several key improvements:

1. **Decentralized Discovery**: Agents can find and interact with each other through on-chain registration and verification.
2. **Hardware-Backed Security**: Integration with Truffle's Jetson Orin hardware ensures sybil resistance through OP-TEE (Trusted Execution Environment).
3. **Off-Chain Efficiency**: While discovery and rules are verified on-chain, agent interactions happen off-chain for scalability.

## Core Components

### 1. Hardware Attestation
The `HardwareAttestation.sol` contract ensures that only legitimate hardware can register as agents through:
- Merkle proof verification of valid serial numbers
- Root key signatures from hardware manufacturers
- Prevention of serial number reuse

### 2. Agent Registry
The `AgentRegistry.sol` contract manages:
- Agent registration with hardware verification
- Staking mechanism for economic security
- Agent metadata and discovery

### 3. Native Token
The `SomeNativeToken.sol` contract provides:
- Native token for staking and payments
- Governance capabilities for protocol upgrades

## Design Decisions

### Root Key System
The protocol uses a root key system where hardware manufacturers sign device attestations because:
- Enables manufacturers to guarantee sybil resistance
- Provides on-chain verification of hardware authenticity
- Creates a trust bridge between physical hardware and the blockchain

### Merkle Proofs for Gas Efficiency
We use Merkle proofs for serial number verification because:
- Manufacturers can update valid serial numbers by only changing the root
- Significantly reduces gas costs compared to storing all serial numbers
- Enables batch updates of many devices with a single transaction

## Future Development

### SDK Development
- Web server integration for agent listening
- Encrypted URL exchange for secure communication
- Payment negotiation and automatic settlement

### Economic Mechanisms
- Review system through restaking
- Reputation-based stake requirements
- Dynamic pricing based on demand

### Technical Improvements
- Gas optimizations for high-volume operations
- Enhanced privacy for agent communications
- Cross-chain agent discovery

## Getting Started

### Prerequisites
- Node.js v14+
- Foundry
- npm or yarn

### Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/agent-registry
cd agent-registry

# Install dependencies
npm install

# Install Foundry dependencies
forge install
```

### Testing
```bash
# Run security test cases
node testing_scripts/security-test-cases.js

# Run contract tests
forge test -vv
```

### Deployment
```bash
# Deploy contracts
forge script script/Deploy.s.sol:Deploy --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Security Considerations

The protocol includes multiple security measures:
1. Hardware attestation to prevent sybil attacks
2. Staking mechanism for economic security
3. Signature verification for authentic hardware
4. Prevention of serial number reuse
5. Merkle proof validation

Run the security test suite to verify these protections:
```bash
node testing_scripts/security-test-cases.js
```

## Gas Optimizations

Current optimizations include:
- Use of Merkle proofs for serial number verification
- Efficient storage patterns in contracts
- Minimal on-chain data storage
- Event-based agent discovery

## Contributing

We welcome contributions! Please see our contributing guidelines for more details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenZeppelin for secure contract implementations
- Truffle for hardware security integration
- The Ethereum community for foundational protocols