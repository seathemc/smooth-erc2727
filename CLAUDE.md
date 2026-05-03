# Smooth ERC-2727 — Setup Instructions

## Project Overview

ERC-2727 is a compliance oracle proof of concept for emerging market assets. It's a Hardhat/Solidity smart contracts project.

## Session Startup

At the start of every session, run these steps automatically:

1. **Pull latest code**
   ```
   git pull origin main
   ```

2. **Install dependencies** (only if `node_modules` is missing)
   ```
   npm install
   ```

3. **Compile contracts**
   ```
   npx hardhat compile
   ```

4. **Run tests** (optional but recommended)
   ```
   npm run test
   ```

## Key Commands

| Task | Command |
|------|---------|
| Compile contracts | `npx hardhat compile` |
| Run tests | `npm run test` |
| Deploy to Sepolia | `npm run deploy` |

## Environment Setup

Create `.env.test` with:
```
PRIVATE_KEY=your_private_key_here
RPC_URL=https://sepolia.infura.io/v3/your_infura_key
```

## Repo Structure

```
contracts/      Solidity contracts (SAISToken, SmoothOracle)
scripts/        Deployment scripts
test/           Test files
```

## Key Contracts

- **SAISToken.sol** — ERC-20 token with compliance transfer hook
- **SmoothOracle.sol** — Mock oracle returning eligibility attestations

## Notes

- Tests verify compliant transfers succeed and non-compliant transfers revert
- Deployment creates `deployment-results.json` with tx hashes
- Requires funded wallet to deploy to Sepolia testnet
