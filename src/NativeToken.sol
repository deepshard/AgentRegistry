// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SomeNativeToken is ERC20, Ownable {
    constructor(address initialOwner) 
        ERC20("Shared Worldwide Agent Registry Marketplace", "SWARM") 
        Ownable(initialOwner)
    {
        // Mint initial supply to owner
        // Let's start with 1 million SWARM tokens
        // Since ERC20 uses 18 decimals by default, we multiply by 10^18
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    // Allow minting of new tokens by owner
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}