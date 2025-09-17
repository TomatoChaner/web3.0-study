const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("🔄 Starting contract interaction...");

    // Read deployment info
    const deploymentFile = path.join(__dirname, `../deployments/${hre.network.name}-deployment.json`);
    
    if (!fs.existsSync(deploymentFile)) {
        console.error("❌ Deployment file not found. Please deploy contracts first.");
        process.exit(1);
    }

    const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, 'utf8'));
    const { contracts } = deploymentInfo;

    // Get signers
    const [deployer, user1, user2] = await ethers.getSigners();
    console.log("👤 Deployer:", deployer.address);
    console.log("👤 User1:", user1.address);
    console.log("👤 User2:", user2.address);

    // Get contract instances
    const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
    const StakeContract = await ethers.getContractFactory("StakeContract");

    const metaNodeToken = MetaNodeToken.attach(contracts.MetaNodeToken.address);
    const stakeContract = StakeContract.attach(contracts.StakeContract.address);

    console.log("\n📊 Initial Contract State:");
    
    // Check token state
    const totalSupply = await metaNodeToken.totalSupply();
    const maxSupply = await metaNodeToken.MAX_SUPPLY();
    const remainingSupply = await metaNodeToken.remainingMintableSupply();
    
    console.log("🪙 Token Info:");
    console.log("   - Total Supply:", ethers.formatEther(totalSupply));
    console.log("   - Max Supply:", ethers.formatEther(maxSupply));
    console.log("   - Remaining Mintable:", ethers.formatEther(remainingSupply));

    // Check stake contract state
    const contractStats = await stakeContract.getContractStats();
    console.log("🏦 Stake Contract Info:");
    console.log("   - Total Staked:", ethers.formatEther(contractStats[0]));
    console.log("   - Total Rewards Distributed:", ethers.formatEther(contractStats[1]));
    console.log("   - Contract Balance:", ethers.formatEther(contractStats[2]));

    // Test staking functionality
    console.log("\n🧪 Testing Staking Functionality:");

    try {
        // User1 stakes 1 ETH
        console.log("\n👤 User1 staking 1 ETH...");
        const stakeAmount = ethers.parseEther("1.0");
        const stakeTx = await stakeContract.connect(user1).stake({ value: stakeAmount });
        await stakeTx.wait();
        console.log("✅ Stake successful, tx:", stakeTx.hash);

        // Check user1's stake info
        const user1StakeInfo = await stakeContract.getUserStakeInfo(user1.address);
        console.log("📊 User1 Stake Info:");
        console.log("   - Amount:", ethers.formatEther(user1StakeInfo[0]));
        console.log("   - Start Time:", new Date(Number(user1StakeInfo[1]) * 1000).toISOString());
        console.log("   - Active:", user1StakeInfo[4]);

        // Wait a bit and check pending rewards
        console.log("\n⏳ Waiting 10 seconds to accumulate rewards...");
        await new Promise(resolve => setTimeout(resolve, 10000));

        const pendingRewards = await stakeContract.getPendingRewards(user1.address);
        console.log("💰 User1 Pending Rewards:", ethers.formatEther(pendingRewards));

        // User2 stakes 0.5 ETH
        console.log("\n👤 User2 staking 0.5 ETH...");
        const stakeAmount2 = ethers.parseEther("0.5");
        const stakeTx2 = await stakeContract.connect(user2).stake({ value: stakeAmount2 });
        await stakeTx2.wait();
        console.log("✅ Stake successful, tx:", stakeTx2.hash);

        // Check updated contract stats
        const updatedStats = await stakeContract.getContractStats();
        console.log("\n📊 Updated Contract Stats:");
        console.log("   - Total Staked:", ethers.formatEther(updatedStats[0]));
        console.log("   - Contract Balance:", ethers.formatEther(updatedStats[2]));

        // Test claiming rewards
        console.log("\n💰 User1 claiming rewards...");
        const claimTx = await stakeContract.connect(user1).claimRewards();
        await claimTx.wait();
        console.log("✅ Rewards claimed, tx:", claimTx.hash);

        // Check user1's token balance
        const user1TokenBalance = await metaNodeToken.balanceOf(user1.address);
        console.log("🪙 User1 Token Balance:", ethers.formatEther(user1TokenBalance));

        // Test partial unstaking
        console.log("\n📤 User1 unstaking 0.5 ETH...");
        const unstakeAmount = ethers.parseEther("0.5");
        const unstakeTx = await stakeContract.connect(user1).unstake(unstakeAmount);
        await unstakeTx.wait();
        console.log("✅ Partial unstake successful, tx:", unstakeTx.hash);

        // Check final state
        const finalUser1StakeInfo = await stakeContract.getUserStakeInfo(user1.address);
        console.log("📊 User1 Final Stake Info:");
        console.log("   - Amount:", ethers.formatEther(finalUser1StakeInfo[0]));
        console.log("   - Active:", finalUser1StakeInfo[4]);

        const finalTokenBalance = await metaNodeToken.balanceOf(user1.address);
        console.log("🪙 User1 Final Token Balance:", ethers.formatEther(finalTokenBalance));

        // Final contract stats
        const finalStats = await stakeContract.getContractStats();
        console.log("\n📊 Final Contract Stats:");
        console.log("   - Total Staked:", ethers.formatEther(finalStats[0]));
        console.log("   - Total Rewards Distributed:", ethers.formatEther(finalStats[1]));
        console.log("   - Contract Balance:", ethers.formatEther(finalStats[2]));

        console.log("\n🎉 All tests completed successfully!");

    } catch (error) {
        console.error("❌ Test failed:");
        console.error(error.message);
        process.exit(1);
    }
}

main()
    .then(() => {
        console.log("\n✅ Interaction completed!");
        process.exit(0);
    })
    .catch((error) => {
        console.error("❌ Interaction failed:");
        console.error(error);
        process.exit(1);
    });