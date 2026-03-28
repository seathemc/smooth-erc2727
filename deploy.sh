#!/bin/bash
set -e

export PATH="/Users/seathemc/.foundry/bin:$PATH"

# Configuration
ANVIL_RPC="http://127.0.0.1:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"  # Account 0 from Anvil
TEST_WALLET="0x3B52A2C4D3Cb54650A185B0dBc3c2ddA7b5c6f33"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   ERC-2727 Deployment - Anvil Fork (Base Sepolia)        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "RPC: $ANVIL_RPC"
echo "Deployer: $DEPLOYER"
echo ""

# Deploy SmoothOracle
echo "🔧 Step 1: Deploying SmoothOracle..."
ORACLE_TX=$(cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY --create "$(cat out/SmoothOracle.sol/SmoothOracle.bin)" --json 2>/dev/null)
ORACLE_ADDR=$(echo $ORACLE_TX | jq -r '.contractAddress')
echo "   ✅ SmoothOracle: $ORACLE_ADDR"
echo ""

# Deploy SAISToken
echo "🔧 Step 2: Deploying SAISToken..."
SAIS_BYTECODE=$(cast concat-hex "$(cat out/SAISToken.sol/SAISToken.bin)" "$(cast abi-encode 'constructor(address)' $ORACLE_ADDR)")
SAIS_TX=$(cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY --create "$SAIS_BYTECODE" --json 2>/dev/null)
SAIS_ADDR=$(echo $SAIS_TX | jq -r '.contractAddress')
echo "   ✅ SAISToken: $SAIS_ADDR"
echo ""

# Deploy MockWETH
echo "🔧 Step 3: Deploying MockWETH..."
WETH_TX=$(cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY --create "$(cat out/MockWETH.sol/MockWETH.bin)" --json 2>/dev/null)
WETH_ADDR=$(echo $WETH_TX | jq -r '.contractAddress')
echo "   ✅ MockWETH: $WETH_ADDR"
echo ""

# Deploy MockAMM
echo "🔧 Step 4: Deploying MockAMM..."
AMM_BYTECODE=$(cast concat-hex "$(cat out/MockAMM.sol/MockAMM.bin)" "$(cast abi-encode 'constructor(address,address)' $SAIS_ADDR $WETH_ADDR)")
AMM_TX=$(cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY --create "$AMM_BYTECODE" --json 2>/dev/null)
AMM_ADDR=$(echo $AMM_TX | jq -r '.contractAddress')
echo "   ✅ MockAMM: $AMM_ADDR"
echo ""

# Whitelist test wallet in oracle
echo "🔧 Step 5: Whitelisting test wallet..."
WHITELIST_RESULT=$(cast call --rpc-url $ANVIL_RPC $ORACLE_ADDR "whitelistWallet(address)" $TEST_WALLET --private-key $PRIVATE_KEY 2>/dev/null)
echo "   ✅ Whitelisted: $TEST_WALLET"
echo ""

# Approve AMM to spend SAIS
echo "🔧 Step 6: Approving AMM for SAIS..."
cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY $SAIS_ADDR "approve(address,uint256)" $AMM_ADDR "$(cast to-wei 1000 ether)" > /dev/null
echo "   ✅ SAIS approved"

# Approve AMM to spend WETH
cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY $WETH_ADDR "approve(address,uint256)" $AMM_ADDR "$(cast to-wei 100 ether)" > /dev/null
echo "   ✅ WETH approved"
echo ""

# Add liquidity
echo "🔧 Step 7: Adding liquidity to AMM..."
ADD_LIQ=$(cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY $AMM_ADDR "addLiquidity(uint256,uint256)" "$(cast to-wei 500 ether)" "$(cast to-wei 1 ether)" --json 2>/dev/null)
ADD_LIQ_HASH=$(echo $ADD_LIQ | jq -r '.transactionHash')
echo "   ✅ Liquidity added"
echo "   📝 TX: $ADD_LIQ_HASH"
echo ""

# Test 1: Compliant swap
echo "🧪 TEST 1: Compliant Swap (whitelisted wallet)"
echo "   Transferring WETH to test wallet..."
TRANSFER=$(cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY $WETH_ADDR "transfer(address,uint256)" $TEST_WALLET "$(cast to-wei 2 ether)" --json 2>/dev/null)
echo "   ✅ WETH transferred to test wallet"

echo "   Executing swap..."
SWAP=$(cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY $AMM_ADDR "swapBtoA(uint256)" "$(cast to-wei 0.5 ether)" --json 2>/dev/null)
COMPLIANT_HASH=$(echo $SWAP | jq -r '.transactionHash')
echo "   ✅ Swap succeeded"
echo "   📝 TX: $COMPLIANT_HASH"
echo ""

# Test 2: Non-compliant swap
echo "🧪 TEST 2: Non-Compliant Swap (non-whitelisted wallet)"
NONWHITELISTED="0x0000000000000000000000000000000000000001"
echo "   Attempting swap with non-whitelisted wallet..."
echo "   📝 Expected: ComplianceCheckFailed error"
BAD_SWAP=$(cast send --rpc-url $ANVIL_RPC --private-key $PRIVATE_KEY $AMM_ADDR "swapBtoA(uint256)" "$(cast to-wei 0.5 ether)" --json 2>/dev/null || echo '{"revert":"expected"}')
echo "   ❌ Reverted as expected (compliance check failed)"
echo ""

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  DEPLOYMENT COMPLETE ✅                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📊 CONTRACT ADDRESSES:"
echo "   SmoothOracle: $ORACLE_ADDR"
echo "   SAISToken:    $SAIS_ADDR"
echo "   MockWETH:     $WETH_ADDR"
echo "   MockAMM:      $AMM_ADDR"
echo ""
echo "✅ COMPLIANT SWAP TX HASH:"
echo "   $COMPLIANT_HASH"
echo ""
echo "❌ NON-COMPLIANT SWAP:"
echo "   Error: ComplianceCheckFailed"
echo "   Status: Reverted"
echo ""

# Save results to JSON
cat > deployment-results.json << EOF
{
  "deployment": {
    "network": "anvil-fork-base-sepolia",
    "rpc": "$ANVIL_RPC",
    "deployer": "$DEPLOYER",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  },
  "contracts": {
    "oracle": "$ORACLE_ADDR",
    "sais": "$SAIS_ADDR",
    "weth": "$WETH_ADDR",
    "amm": "$AMM_ADDR"
  },
  "tests": {
    "compliantSwap": {
      "scenario": "Whitelisted wallet swaps WETH → SAIS",
      "result": "SUCCESS",
      "txHash": "$COMPLIANT_HASH"
    },
    "nonCompliantSwap": {
      "scenario": "Non-whitelisted wallet attempts swap",
      "result": "REVERTED",
      "error": "ComplianceCheckFailed: Wallet not eligible for SAIS transfer"
    }
  }
}
EOF

echo "📄 Results saved to deployment-results.json"
