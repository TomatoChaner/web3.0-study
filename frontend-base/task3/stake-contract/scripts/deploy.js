const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("🚀 Starting deployment process...");
    
    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log("📝 Deploying contracts with account:", deployer.address);
    
    // Check deployer balance
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("💰 Account balance:", ethers.formatEther(balance), "ETH");
    
    if (balance < ethers.parseEther("0.1")) {
        console.warn("⚠️  Warning: Low balance. Make sure you have enough ETH for deployment.");
    }

    // Deploy MetaNodeToken
    console.log("\n📦 Deploying MetaNodeToken...");
    const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
    
    // Token parameters
    const tokenName = "MetaNode Token";
    const tokenSymbol = "MNT";
    const initialSupply = ethers.parseEther("1000000"); // 1M tokens initial supply
    
    const metaNodeToken = await MetaNodeToken.deploy(
        tokenName,
        tokenSymbol,
        initialSupply
    );
    
    console.log("✅ MetaNodeToken deployed to:", metaNodeToken.target);
    console.log("   - Name:", tokenName);
    console.log("   - Symbol:", tokenSymbol);
    console.log("   - Initial Supply:", ethers.formatEther(initialSupply));

    // Deploy StakeContract
    console.log("\n📦 Deploying StakeContract...");
    const StakeContract = await ethers.getContractFactory("StakeContract");
    
    const stakeContract = await StakeContract.deploy(metaNodeToken.target);
    console.log("✅ StakeContract deployed to:", stakeContract.target);

    // Grant MINTER_ROLE to StakeContract
    console.log("\n🔑 Setting up permissions...");
    const grantTx = await metaNodeToken.grantMinterRole(stakeContract.target);
    await grantTx.wait();
    console.log("✅ Granted MINTER_ROLE to StakeContract");

    // Verify the setup
    console.log("\n🔍 Verifying deployment...");
    
    // Check token details
    const tokenTotalSupply = await metaNodeToken.totalSupply();
    const tokenMaxSupply = await metaNodeToken.MAX_SUPPLY();
    const remainingSupply = await metaNodeToken.remainingMintableSupply();
    
    console.log("📊 Token Information:");
    console.log("   - Total Supply:", ethers.formatEther(tokenTotalSupply));
    console.log("   - Max Supply:", ethers.formatEther(tokenMaxSupply));
    console.log("   - Remaining Mintable:", ethers.formatEther(remainingSupply));
    
    // Check stake contract details
    const rewardToken = await stakeContract.rewardToken();
    const totalStaked = await stakeContract.totalStaked();
    
    console.log("📊 Stake Contract Information:");
    console.log("   - Reward Token:", rewardToken);
    console.log("   - Total Staked:", ethers.formatEther(totalStaked));
    console.log("   - Min Stake Amount:", ethers.formatEther(await stakeContract.MIN_STAKE_AMOUNT()));
    console.log("   - Max Stake Amount:", ethers.formatEther(await stakeContract.MAX_STAKE_AMOUNT()));

    // Save deployment information
    const deploymentInfo = {
        network: hre.network.name,
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
        contracts: {
            MetaNodeToken: {
                address: metaNodeToken.target,
                name: tokenName,
                symbol: tokenSymbol,
                initialSupply: initialSupply.toString(),
                maxSupply: tokenMaxSupply.toString()
            },
            StakeContract: {
                address: stakeContract.target,
                rewardToken: metaNodeToken.target,
                minStakeAmount: (await stakeContract.MIN_STAKE_AMOUNT()).toString(),
                maxStakeAmount: (await stakeContract.MAX_STAKE_AMOUNT()).toString(),
                rewardRate: (await stakeContract.REWARD_RATE()).toString()
            }
        },
        transactionHashes: {
            metaNodeToken: metaNodeToken.deploymentTransaction()?.hash || "N/A",
            stakeContract: stakeContract.deploymentTransaction()?.hash || "N/A",
            grantMinterRole: grantTx.hash
        }
    };

    // Create deployments directory if it doesn't exist
    const deploymentsDir = path.join(__dirname, "../deployments");
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir, { recursive: true });
    }

    // Save deployment info to file
    const deploymentFile = path.join(deploymentsDir, `${hre.network.name}-deployment.json`);
    fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
    console.log(`\n💾 Deployment info saved to: ${deploymentFile}`);

    // Generate ABI files for frontend
    const abisDir = path.join(__dirname, "../abis");
    if (!fs.existsSync(abisDir)) {
        fs.mkdirSync(abisDir, { recursive: true });
    }

    // Save ABIs
    const metaNodeTokenArtifact = await hre.artifacts.readArtifact("MetaNodeToken");
    const stakeContractArtifact = await hre.artifacts.readArtifact("StakeContract");

    fs.writeFileSync(
        path.join(abisDir, "MetaNodeToken.json"),
        JSON.stringify({
            address: metaNodeToken.target,
            abi: metaNodeTokenArtifact.abi
        }, null, 2)
    );

    fs.writeFileSync(
        path.join(abisDir, "StakeContract.json"),
        JSON.stringify({
            address: stakeContract.target,
            abi: stakeContractArtifact.abi
        }, null, 2)
    );

    console.log("📄 ABI files generated in ./abis/");

    console.log("\n🎉 Deployment completed successfully!");
    console.log("\n📋 Summary:");
    console.log("   MetaNodeToken:", metaNodeToken.target);
    console.log("   StakeContract:", stakeContract.target);
    console.log("\n🔗 Next steps:");
    console.log("   1. Verify contracts on Etherscan (if on mainnet/testnet)");
    console.log("   2. Update frontend configuration with new addresses");
    console.log("   3. Run tests to ensure everything works correctly");
    
    return {
        metaNodeToken: metaNodeToken.target,
        stakeContract: stakeContract.target
    };
}

// Handle errors
main()
    .then((addresses) => {
        console.log("\n✅ Deployment successful!");
        process.exit(0);
    })
    .catch((error) => {
        console.error("\n❌ Deployment failed:");
        console.error(error);
        process.exit(1);
    });