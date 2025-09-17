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
    
    if (balance < ethers.parseEther("0.01")) {
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
    
    await metaNodeToken.waitForDeployment();
    console.log("✅ MetaNodeToken deployed to:", metaNodeToken.target);
    console.log("   - Name:", tokenName);
    console.log("   - Symbol:", tokenSymbol);
    console.log("   - Initial Supply:", ethers.formatEther(initialSupply));

    // Deploy StakeContract
    console.log("\n📦 Deploying StakeContract...");
    const StakeContract = await ethers.getContractFactory("StakeContract");
    
    const stakeContract = await StakeContract.deploy(metaNodeToken.target);
    await stakeContract.waitForDeployment();
    console.log("✅ StakeContract deployed to:", stakeContract.target);

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
                initialSupply: initialSupply.toString()
            },
            StakeContract: {
                address: stakeContract.target,
                rewardToken: metaNodeToken.target
            }
        }
    };

    // Save to file
    const deploymentsDir = path.join(__dirname, "..", "deployments");
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir, { recursive: true });
    }
    
    const deploymentFile = path.join(deploymentsDir, `${hre.network.name}-deployment.json`);
    fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
    
    console.log("\n📄 Deployment information saved to:", deploymentFile);
    console.log("\n🎉 Deployment completed successfully!");
    console.log("\n📋 Contract Addresses:");
    console.log("   MetaNodeToken:", metaNodeToken.target);
    console.log("   StakeContract:", stakeContract.target);
    
    console.log("\n⚠️  Next steps:");
    console.log("   1. Grant MINTER_ROLE to StakeContract");
    console.log("   2. Update frontend configuration");
    console.log("   3. Test the deployment");

    return {
        metaNodeToken: metaNodeToken.target,
        stakeContract: stakeContract.target
    };
}

main()
    .then((addresses) => {
        console.log("\n✅ All contracts deployed successfully!");
        process.exit(0);
    })
    .catch((error) => {
        console.error("\n❌ Deployment failed:", error);
        process.exit(1);
    });