const express = require('express');
const { ethers } = require('ethers');
const app = express();

// ABI snippets we need
const REGISTRY_ABI = [
    "event StakeDeposited(uint256 indexed agentId, address indexed staker, uint256 amount)",
    "function agents(uint256) view returns (address owner, uint256 minStake, bool active, string metadataURI)"
];

class StakeWebhookServer {
    constructor(config) {
        this.provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
        this.registry = new ethers.Contract(
            config.registryAddress,
            REGISTRY_ABI,
            this.provider
        );
        
        this.setupEventListeners();
    }

    setupEventListeners() {
        this.registry.on("StakeDeposited", async (agentId, staker, amount, event) => {
            console.log('New stake detected!');
            console.log({
                agentId: agentId.toString(),
                staker,
                amount: ethers.utils.formatEther(amount),
                transactionHash: event.transactionHash
            });

            // Get agent details
            const agent = await this.registry.agents(agentId);
            console.log('Agent details:', {
                owner: agent.owner,
                minStake: ethers.utils.formatEther(agent.minStake),
                active: agent.active,
                metadataURI: agent.metadataURI
            });

            // Here you can add your custom webhook logic
            // For example, sending a notification to your system
        });
    }
}

// Create server
const server = new StakeWebhookServer({
    rpcUrl: 'http://localhost:8545',
    registryAddress: process.env.REGISTRY_ADDRESS
});

// Basic health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Webhook server listening on port ${PORT}`);
});