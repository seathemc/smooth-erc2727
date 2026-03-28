// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISmoothOracle {
    function isEligible(address wallet, string memory jurisdiction) external returns (bool);
}

contract SAISToken is ERC20, Ownable {
    ISmoothOracle public smoothOracle;
    string public jurisdiction = "ZA"; // South African jurisdiction

    event OracleUpdated(address indexed newOracle);
    event ComplianceCheckFailed(address indexed wallet, string reason);

    constructor(address _oracle) ERC20("SA Infrastructure Share", "SAIS") Ownable(msg.sender) {
        smoothOracle = ISmoothOracle(_oracle);
        _mint(msg.sender, 1000000 * 10 ** decimals()); // 1M tokens
    }

    function setOracle(address _oracle) external onlyOwner {
        smoothOracle = ISmoothOracle(_oracle);
        emit OracleUpdated(_oracle);
    }

    function _update(address from, address to, uint256 amount) internal override {
        // Skip compliance check for minting
        if (from != address(0)) {
            // Check if recipient is eligible to receive SAIS tokens
            require(
                smoothOracle.isEligible(to, jurisdiction),
                "ComplianceCheckFailed: Wallet not eligible for SAIS transfer"
            );
        }
        super._update(from, to, amount);
    }
}
