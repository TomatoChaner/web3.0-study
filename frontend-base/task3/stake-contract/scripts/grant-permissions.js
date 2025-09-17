const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("🔑 Starting permission setup...");
    
    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log("📝 Using account:", deployer.address);
    
    // Load deployment information
    const deploymentFile = path.join(__dirname, "..", "deployments", `${hre.network.name}-deployment.json`);
    
    if (!fs.existsSync(deploymentFile)) {
        throw new Error(`Deployment file not found: ${deploymentFile}`);
    }
    
    const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, 'utf8'));
    const metaNodeTokenAddress = deploymentInfo.contracts.MetaNodeToken.address;
    const stakeContractAddress = deploymentInfo.contracts.StakeContract.address;
    
    console.log("📋 Contract Addresses:");
    console.log("   MetaNodeToken:", metaNodeTokenAddress);
    console.log("   StakeContract:", stakeContractAddress);
    
    // Get contract instances
    const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
    const metaNodeToken = MetaNodeToken.attach(metaNodeTokenAddress);
    
    // Grant MINTER_ROLE to StakeContract
    console.log("\n🔑 Granting MINTER_ROLE to StakeContract...");
    
    try {
        const grantTx = await metaNodeToken.grantMinterRole(stakeContractAddress);
        console.log("📤 Transaction sent:", grantTx.hash);
        
        const receipt = await grantTx.wait();
        console.log("✅ MINTER_ROLE granted successfully!");
        console.log("   Block number:", receipt.blockNumber);
        console.log("   Gas used:", receipt.gasUsed.toString());
        
        // Verify the role was granted
        const hasRole = await metaNodeToken.hasRole(
            await metaNodeToken.MINTER_ROLE(),
            stakeContractAddress
        );
        
        if (hasRole) {
            console.log("✅ Verification: StakeContract has MINTER_ROLE");
        } else {
            console.log("❌ Verification failed: StakeContract does not have MINTER_ROLE");
        }
        
    } catch (error) {
        console.error("❌ Failed to grant MINTER_ROLE:", error.message);
        throw error;
    }
    
    console.log("\n🎉 Permission setup completed successfully!");
}

main()
    .then(() => {
        console.log("\n✅ All permissions configured!");
        process.exit(0);
    })
    .catch((error) => {
        console.error("\n❌ Permission setup failed:", error);
        process.exit(1);
    });