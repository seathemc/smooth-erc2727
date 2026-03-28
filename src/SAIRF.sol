// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISmoothOracle {
    function isEligible(address wallet, string memory jurisdiction) external returns (bool);
}

/**
 * @dev South African Institutional Real Estate Fund (SAIRF)
 * - 400 tokens, $1000 USDC each = $400K total
 * - Compliance-restricted: only whitelisted wallets can receive
 * - Issued by ZA, purchased by SGP entities
 */
contract SAIRF is ERC20, Ownable {
    ISmoothOracle public smoothOracle;
    string public issuerJurisdiction = "ZA";
    string public buyerJurisdiction = "SGP";

    event OracleUpdated(address indexed newOracle);
    event ComplianceCheckFailed(address indexed wallet, string reason);

    constructor(address _oracle) ERC20("SA Institutional Real Estate Fund", "SAIRF") Ownable(msg.sender) {
        smoothOracle = ISmoothOracle(_oracle);
        _mint(msg.sender, 400 * 10 ** decimals()); // 400 tokens
    }

    function setOracle(address _oracle) external onlyOwner {
        smoothOracle = ISmoothOracle(_oracle);
        emit OracleUpdated(_oracle);
    }

    function _update(address from, address to, uint256 amount) internal override {
        // Skip compliance check for minting
        if (from != address(0)) {
            // Check if recipient is eligible to receive SAIRF tokens
            require(
                smoothOracle.isEligible(to, buyerJurisdiction),
                "ComplianceCheckFailed: Wallet not eligible for SAIRF transfer"
            );
        }
        super._update(from, to, amount);
    }
}
