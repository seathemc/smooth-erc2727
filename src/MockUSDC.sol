// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Mock USDC for SAIRF testing
 * 1 token = 1 USDC, 100M supply
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 100_000_000 * 10 ** decimals()); // 100M USDC
    }
}
