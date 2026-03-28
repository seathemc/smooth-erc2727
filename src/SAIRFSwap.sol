// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Simple fixed-price AMM for SAIRF/USDC
 * Price: 1 SAIRF = 1000 USDC (fixed)
 */
contract SAIRFSwap is Ownable {
    IERC20 public sairf;
    IERC20 public usdc;
    uint256 public constant PRICE = 1000 * 10 ** 6; // 1000 USDC (6 decimals)

    event Swap(address indexed trader, uint256 sairfAmount, uint256 usdcAmount, string direction);

    constructor(address _sairf, address _usdc) Ownable(msg.sender) {
        sairf = IERC20(_sairf);
        usdc = IERC20(_usdc);
    }

    /**
     * @dev Swap USDC for SAIRF (buy SAIRF with USDC)
     * User sends USDC, receives SAIRF at 1 SAIRF = 1000 USDC
     */
    function swapUSDCforSAIRF(uint256 usdcAmount) external returns (uint256 sairfAmount) {
        require(usdcAmount > 0, "Invalid USDC amount");
        require(usdcAmount % PRICE == 0, "USDC amount must be multiple of 1000");

        sairfAmount = usdcAmount / PRICE;
        
        // Transfer USDC from user to contract
        require(usdc.transferFrom(msg.sender, address(this), usdcAmount), "USDC transfer failed");
        
        // Transfer SAIRF from contract to user (triggers compliance hook!)
        require(sairf.transfer(msg.sender, sairfAmount), "SAIRF transfer failed");
        
        emit Swap(msg.sender, sairfAmount, usdcAmount, "buy");
    }

    /**
     * @dev Swap SAIRF for USDC (sell SAIRF for USDC)
     */
    function swapSAIRFforUSDC(uint256 sairfAmount) external returns (uint256 usdcAmount) {
        require(sairfAmount > 0, "Invalid SAIRF amount");
        
        usdcAmount = sairfAmount * PRICE;
        
        // Transfer SAIRF from user to contract
        require(sairf.transferFrom(msg.sender, address(this), sairfAmount), "SAIRF transfer failed");
        
        // Transfer USDC from contract to user
        require(usdc.transfer(msg.sender, usdcAmount), "USDC transfer failed");
        
        emit Swap(msg.sender, sairfAmount, usdcAmount, "sell");
    }

    /**
     * @dev Check SAIRF balance in contract
     */
    function getSAIRFBalance() external view returns (uint256) {
        return sairf.balanceOf(address(this));
    }

    /**
     * @dev Check USDC balance in contract
     */
    function getUSDCBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}
