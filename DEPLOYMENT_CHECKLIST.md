# Deployment Readiness Checklist — Base Sepolia

## Pre-Deployment ✅
- [x] `SAISToken.sol` — ERC-20 with compliance transfer hook
- [x] `SmoothOracle.sol` — Mock oracle with whitelisting + EIP-712
- [x] `MockWETH.sol` — Test WETH token
- [x] `MockAMM.sol` — Minimal constant-product AMM (self-contained, no Uniswap dependency)
- [x] `hardhat.config.js` — Configured for Base Sepolia (Chain ID 84532)
- [x] `scripts/deploy.js` — Full automation: deploy → whitelist → add liquidity → test swaps
- [x] `.env.test` — Private key + RPC endpoint configured
- [x] `package.json` — Hardhat + OpenZeppelin dependencies
- [x] Project structure clean (no conflicts, no duplicate files)

## Deployment Flow (Execute When Wallet Funded)

```bash
cd /Users/seathemc/Documents/smooth

# 1. Install dependencies (one-time)
npm install

# 2. Verify contracts compile
npx hardhat compile

# 3. Deploy to Base Sepolia (requires ~0.05 ETH for gas)
npm run deploy
```

## What Gets Deployed
1. **SmoothOracle** — Whitelisting oracle with EIP-712 attestations
2. **SAISToken** — ERC-20 with compliance transfer hook
3. **MockWETH** — Test WETH (base asset for AMM)
4. **MockAMM** — SAIS/WETH liquidity pool (constant product formula)

## What Gets Tested
1. ✅ **Compliant Swap** — Whitelisted wallet swaps WETH → SAIS (succeeds)
2. ❌ **Non-Compliant Swap** — Non-whitelisted wallet attempts swap (reverts with ComplianceCheckFailed)

## Expected Output
After deployment:
- 4 contract addresses (oracle, SAIS, WETH, AMM)
- Compliant swap TX hash (✅ succeeded)
- Non-compliant swap revert (❌ ComplianceCheckFailed)
- Full results saved to `deployment-results.json`
- Explorer links for Base Sepolia Basescan

## Network Info
- **Chain:** Base Sepolia
- **Chain ID:** 84532
- **RPC:** https://sepolia.base.org
- **Explorer:** https://sepolia.basescan.org
- **Wallet:** 0x3B52A2C4D3Cb54650A185B0dBc3c2ddA7b5c6f33
- **Faucet:** https://www.coinbase.com/faucets/base-ethereum-sepolia

## Troubleshooting
- **"Insufficient balance"** — Wallet needs Base Sepolia ETH (waiting for faucet)
- **"Network error"** — Verify RPC_URL in `.env.test`
- **"Contract compilation failed"** — Run `npm install` to get OpenZeppelin contracts
- **"Private key error"** — Ensure PRIVATE_KEY is in `.env.test`

---

**Status: READY FOR DEPLOYMENT** ✅  
Awaiting wallet funding confirmation from Marvin.
