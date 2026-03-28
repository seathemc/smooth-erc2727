const hre = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("\n╔═══════════════════════════════════════════════════════════╗");
  console.log("║   ERC-2727 Smooth Oracle Deployment - Base Sepolia      ║");
  console.log("╚═══════════════════════════════════════════════════════════╝\n");

  const [deployer] = await hre.ethers.getSigners();
  console.log(`📋 Deployer: ${deployer.address}`);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`💰 Balance: ${hre.ethers.formatEther(balance)} ETH`);
  console.log(`🌐 Network: Base Sepolia (Chain ID 84532)\n`);

  // Deploy SmoothOracle
  console.log("🔧 Step 1: Deploying SmoothOracle...");
  const Oracle = await hre.ethers.getContractFactory("SmoothOracle");
  const oracle = await Oracle.deploy();
  await oracle.waitForDeployment();
  const oracleAddr = await oracle.getAddress();
  console.log(`   ✅ SmoothOracle: ${oracleAddr}\n`);

  // Deploy SAISToken
  console.log("🔧 Step 2: Deploying SAISToken (with oracle)...");
  const SAIS = await hre.ethers.getContractFactory("SAISToken");
  const sais = await SAIS.deploy(oracleAddr);
  await sais.waitForDeployment();
  const saisAddr = await sais.getAddress();
  console.log(`   ✅ SAISToken: ${saisAddr}\n`);

  // Deploy MockWETH
  console.log("🔧 Step 3: Deploying MockWETH...");
  const WETH = await hre.ethers.getContractFactory("MockWETH");
  const weth = await WETH.deploy();
  await weth.waitForDeployment();
  const wethAddr = await weth.getAddress();
  console.log(`   ✅ MockWETH: ${wethAddr}\n`);

  // Deploy MockAMM
  console.log("🔧 Step 4: Deploying MockAMM (SAIS/WETH pool)...");
  const AMM = await hre.ethers.getContractFactory("MockAMM");
  const amm = await AMM.deploy(saisAddr, wethAddr);
  await amm.waitForDeployment();
  const ammAddr = await amm.getAddress();
  console.log(`   ✅ MockAMM: ${ammAddr}\n`);

  // Whitelist test wallet in oracle
  console.log("🔧 Step 5: Whitelisting test wallet in oracle...");
  const testWallet = process.env.TEST_WALLET || "0x3B52A2C4D3Cb54650A185B0dBc3c2ddA7b5c6f33";
  const whitelistTx = await oracle.whitelistWallet(testWallet);
  await whitelistTx.wait();
  console.log(`   ✅ Whitelisted: ${testWallet}\n`);

  // Add liquidity to AMM
  console.log("🔧 Step 6: Adding liquidity to AMM...");
  const saisAmount = hre.ethers.parseEther("500");
  const wethAmount = hre.ethers.parseEther("1");

  // Approve AMM to spend tokens
  await sais.approve(ammAddr, saisAmount);
  await weth.approve(ammAddr, wethAmount);

  // Add liquidity
  const addLiqTx = await amm.addLiquidity(saisAmount, wethAmount);
  const addLiqReceipt = await addLiqTx.wait();
  console.log(`   ✅ Liquidity added: 500 SAIS + 1 WETH`);
  console.log(`   📝 TX: ${addLiqReceipt.hash}\n`);

  // Test 1: Compliant swap through AMM
  console.log("🧪 TEST 1: Compliant Swap (whitelisted wallet)");
  console.log("   Swapping 100 WETH for SAIS through AMM...");
  try {
    // First, transfer WETH to test wallet
    await weth.transfer(testWallet, hre.ethers.parseEther("2"));

    // Have test wallet approve AMM
    const testWalletSigner = await hre.ethers.getSigner(testWallet);
    const ammAsTestWallet = amm.connect(testWalletSigner);
    const wethAsTestWallet = weth.connect(testWalletSigner);

    await wethAsTestWallet.approve(ammAddr, hre.ethers.parseEther("100"));

    // Execute swap (will trigger SAIS transfer hook with compliance check)
    const swapTx = await ammAsTestWallet.swapBtoA(hre.ethers.parseEther("0.5"));
    const swapReceipt = await swapTx.wait();

    console.log(`   ✅ Swap succeeded`);
    console.log(`   📝 TX Hash: ${swapReceipt.hash}`);
    console.log(`   ⛽ Gas used: ${swapReceipt.gasUsed.toString()}\n`);

    const compliantTx = swapReceipt.hash;

    // Test 2: Non-compliant swap
    console.log("🧪 TEST 2: Non-Compliant Swap (non-whitelisted wallet)");
    const nonWhitelistedAddr = "0x0000000000000000000000000000000000000001";
    console.log(`   Attempting swap to non-whitelisted: ${nonWhitelistedAddr}...`);
    try {
      // Send WETH to non-whitelisted address
      await weth.transfer(nonWhitelistedAddr, hre.ethers.parseEther("1"));

      const nonWhitelistedSigner = await hre.ethers.getSigner(nonWhitelistedAddr);
      const ammAsNonWhitelisted = amm.connect(nonWhitelistedSigner);
      const wethAsNonWhitelisted = weth.connect(nonWhitelistedSigner);

      await wethAsNonWhitelisted.approve(ammAddr, hre.ethers.parseEther("1"));

      const badSwapTx = await ammAsNonWhitelisted.swapBtoA(hre.ethers.parseEther("0.5"));
      const badReceipt = await badSwapTx.wait();
      console.log(`   ❌ ERROR: Swap should have reverted but succeeded!`);
    } catch (error) {
      if (error.message.includes("ComplianceCheckFailed")) {
        console.log(`   ✅ Swap reverted as expected`);
        console.log(`   📝 Error: ComplianceCheckFailed`);
        console.log(`   📝 Reason: Wallet not eligible for SAIS transfer\n`);

        // Save results
        const results = {
          deployment: {
            network: "base-sepolia",
            chainId: 84532,
            rpc: "https://sepolia.base.org",
            deployer: deployer.address,
            testWallet: testWallet,
            timestamp: new Date().toISOString()
          },
          contracts: {
            oracle: oracleAddr,
            sais: saisAddr,
            weth: wethAddr,
            amm: ammAddr
          },
          tests: {
            compliantSwap: {
              scenario: "Whitelisted wallet swaps WETH → SAIS through AMM",
              result: "SUCCESS",
              txHash: compliantTx,
              message: "Swap executed successfully (oracle approved transfer)"
            },
            nonCompliantSwap: {
              scenario: "Non-whitelisted wallet attempts WETH → SAIS swap",
              result: "REVERTED",
              error: "ComplianceCheckFailed: Wallet not eligible for SAIS transfer",
              message: "Swap reverted at token transfer (compliance hook enforced)"
            }
          }
        };

        fs.writeFileSync("deployment-results.json", JSON.stringify(results, null, 2));

        console.log("╔═══════════════════════════════════════════════════════════╗");
        console.log("║                 DEPLOYMENT SUCCESS ✅                    ║");
        console.log("╚═══════════════════════════════════════════════════════════╝");
        console.log(`
📊 CONTRACTS DEPLOYED:
   SmoothOracle: ${oracleAddr}
   SAISToken:    ${saisAddr}
   MockWETH:     ${wethAddr}
   MockAMM:      ${ammAddr}

✅ COMPLIANT SWAP (whitelisted wallet):
   TX: ${compliantTx}
   Explorer: https://sepolia.basescan.org/tx/${compliantTx}

❌ NON-COMPLIANT SWAP (non-whitelisted wallet):
   Error: ComplianceCheckFailed
   Status: Reverted at transfer hook

🔗 PROOF OF CONCEPT:
   ERC-2727 compliance oracle enforcement verified
   AMM integration demonstrates liquidity with compliance gates
   Full results saved to: deployment-results.json
        `);
      } else {
        throw error;
      }
    }
  } catch (error) {
    console.error("❌ Deployment failed:", error.message);
    process.exit(1);
  }
}

main();
