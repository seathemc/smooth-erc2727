# Smooth ERC-2727 PoC

## Overview
Proof of concept for ERC-2727 compliance oracle enabling cross-border capital liquidity for emerging market assets.

**Key Components:**
- `SAISToken.sol` — ERC-20 token with compliance transfer hook
- `SmoothOracle.sol` — Mock oracle returning eligibility attestations
- Hardhat deployment + test scripts

## Setup

```bash
# Install dependencies
npm install

# Verify contracts compile
npx hardhat compile

# Deploy to Sepolia (requires funded wallet)
npm run deploy
```

## Environment Variables
`.env.test` contains:
- `PRIVATE_KEY` — Deployer private key
- `RPC_URL` — Sepolia RPC endpoint

## Deployment Flow
1. Deploy `SmoothOracle` contract
2. Deploy `SAISToken` contract with oracle address
3. Whitelist test wallet in oracle
4. Test: Compliant transfer (whitelisted wallet) → **succeeds**
5. Test: Non-compliant transfer (non-whitelisted wallet) → **reverts with ComplianceCheckFailed**

## Expected TX Hashes
After deployment and tests, `deployment-results.json` will contain:
- ✅ Compliant swap tx hash
- ❌ Non-compliant swap revert tx

## Next Steps
- Create Uniswap v2 pool for SAIS/WETH
- Execute swaps through AMM (compliance enforced at token level)
- Record Uniswap pool creation and swap tx hashes
