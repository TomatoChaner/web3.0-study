const { run } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("🔍 Starting contract verification...");

    // Read deployment info
    const deploymentFile = path.join(__dirname, `../deployments/${hre.network.name}-deployment.json`);
    
    if (!fs.existsSync(deploymentFile)) {
        console.error("❌ Deployment file not found. Please deploy contracts first.");
        process.exit(1);
    }

    const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, 'utf8'));
    const { contracts } = deploymentInfo;

    try {
        // Verify MetaNodeToken
        console.log("\n📝 Verifying MetaNodeToken...");
        await run("verify:verify", {
            address: contracts.MetaNodeToken.address,
            constructorArguments: [
                contracts.MetaNodeToken.name,
                contracts.MetaNodeToken.symbol,
                contracts.MetaNodeToken.initialSupply
            ],
        });
        console.log("✅ MetaNodeToken verified successfully");

        // Verify StakeContract
        console.log("\n📝 Verifying StakeContract...");
        await run("verify:verify", {
            address: contracts.StakeContract.address,
            constructorArguments: [
                contracts.MetaNodeToken.address
            ],
        });
        console.log("✅ StakeContract verified successfully");

        console.log("\n🎉 All contracts verified successfully!");

    } catch (error) {
        console.error("❌ Verification failed:");
        console.error(error.message);
        
        if (error.message.includes("Already Verified")) {
            console.log("ℹ️  Contracts are already verified");
        } else {
            process.exit(1);
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });