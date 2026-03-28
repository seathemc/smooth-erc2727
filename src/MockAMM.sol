// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Minimal constant product AMM for SAIS/WETH pair.
 * Used for PoC testing only. Not suitable for production.
 *
 * Implements basic x*y=k formula for two-token swaps.
 */
contract MockAMM is Ownable {
    IERC20 public tokenA; // SAIS
    IERC20 public tokenB; // WETH (or ETH wrapper)

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLiquidity;

    mapping(address => uint256) public liquidityShares;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(address indexed trader, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /**
     * @dev Add liquidity to the pool
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 liquidity) {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        // Transfer tokens from user
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "TokenA transfer failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "TokenB transfer failed");

        if (totalLiquidity == 0) {
            // First liquidity provider
            liquidity = sqrt(amountA * amountB);
        } else {
            // Calculate liquidity proportionally
            uint256 liquidityA = (amountA * totalLiquidity) / reserveA;
            uint256 liquidityB = (amountB * totalLiquidity) / reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        require(liquidity > 0, "Insufficient liquidity provided");

        reserveA += amountA;
        reserveB += amountB;
        totalLiquidity += liquidity;
        liquidityShares[msg.sender] += liquidity;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    /**
     * @dev Swap tokenA for tokenB (SAIS → WETH)
     */
    function swapAtoB(uint256 amountAIn) external returns (uint256 amountBOut) {
        require(amountAIn > 0, "Invalid input amount");

        // Transfer input token
        require(tokenA.transferFrom(msg.sender, address(this), amountAIn), "TokenA transfer failed");

        // Calculate output using x*y=k
        // amountOut = (amountIn * reserveB) / (reserveA + amountIn)
        uint256 denominator = reserveA + amountAIn;
        amountBOut = (amountAIn * reserveB) / denominator;

        require(amountBOut > 0, "Insufficient output amount");
        require(amountBOut <= reserveB, "Insufficient liquidity");

        // Update reserves
        reserveA += amountAIn;
        reserveB -= amountBOut;

        // Transfer output token
        require(tokenB.transfer(msg.sender, amountBOut), "TokenB transfer failed");

        emit Swap(msg.sender, address(tokenA), amountAIn, amountBOut);
    }

    /**
     * @dev Swap tokenB for tokenA (WETH → SAIS)
     */
    function swapBtoA(uint256 amountBIn) external returns (uint256 amountAOut) {
        require(amountBIn > 0, "Invalid input amount");

        // Transfer input token
        require(tokenB.transferFrom(msg.sender, address(this), amountBIn), "TokenB transfer failed");

        // Calculate output
        uint256 denominator = reserveB + amountBIn;
        amountAOut = (amountBIn * reserveA) / denominator;

        require(amountAOut > 0, "Insufficient output amount");
        require(amountAOut <= reserveA, "Insufficient liquidity");

        // Update reserves
        reserveB += amountBIn;
        reserveA -= amountAOut;

        // Transfer output token (will trigger SAIS transfer hook!)
        require(tokenA.transfer(msg.sender, amountAOut), "TokenA transfer failed");

        emit Swap(msg.sender, address(tokenB), amountBIn, amountAOut);
    }

    /**
     * @dev Get swap output amount (without execution)
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "Invalid input");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");

        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    /**
     * @dev Simple square root (for liquidity calculation)
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
