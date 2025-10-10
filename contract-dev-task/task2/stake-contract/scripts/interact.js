const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    const [signer] = await ethers.getSigners();
    console.log("Interacting with contracts using account:", signer.address);

    // Load deployment info
    const deploymentFile = path.join(__dirname, "..", "deployments", `${hre.network.name}.json`);
    if (!fs.existsSync(deploymentFile)) {
        console.error("Deployment file not found. Please deploy contracts first.");
        process.exit(1);
    }

    const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
    const stakeContractAddress = deploymentInfo.contracts.MetaNodeStake;
    const metaNodeTokenAddress = deploymentInfo.contracts.MetaNodeToken;

    console.log("MetaNodeStake contract:", stakeContractAddress);
    console.log("MetaNode Token:", metaNodeTokenAddress);

    // Get contract instances
    const stakeContract = await ethers.getContractAt("MetaNodeStake", stakeContractAddress);
    const metaNodeToken = await ethers.getContractAt("MockERC20", metaNodeTokenAddress);

    // Display contract info
    console.log("\n=== Contract Information ===");
    console.log("Reward per block:", ethers.formatEther(await stakeContract.rewardPerBlock()), "META");
    console.log("Total pool weight:", await stakeContract.totalPoolWeight());
    console.log("Number of pools:", await stakeContract.poolLength());

    // Display pool information
    const poolCount = await stakeContract.poolLength();
    for (let i = 0; i < poolCount; i++) {
        const pool = await stakeContract.getPool(i);
        console.log(`\nPool ${i}:`);
        console.log("  Token:", pool.stTokenAddress === "0x0000000000000000000000000000000000000000" ? "ETH" : pool.stTokenAddress);
        console.log("  Weight:", pool.poolWeight.toString());
        console.log("  Min deposit:", ethers.formatEther(pool.minDepositAmount));
        console.log("  Lock blocks:", pool.unstakeLockedBlocks.toString());
        console.log("  Total staked:", ethers.formatEther(pool.stTokenAmount));
        console.log("  Last reward block:", pool.lastRewardBlock.toString());
    }

    // Display user information
    console.log("\n=== User Information ===");
    for (let i = 0; i < poolCount; i++) {
        const user = await stakeContract.getUser(i, signer.address);
        if (user.stAmount > 0) {
            console.log(`Pool ${i}:`);
            console.log("  Staked amount:", ethers.formatEther(user.stAmount));
            console.log("  Pending rewards:", ethers.formatEther(user.pendingMetaNode));
            
            const pendingReward = await stakeContract.pendingReward(i, signer.address);
            console.log("  Total pending:", ethers.formatEther(pendingReward));

            const withdrawable = await stakeContract.getWithdrawableAmount(i, signer.address);
            console.log("  Withdrawable:", ethers.formatEther(withdrawable));

            const requests = await stakeContract.getUserUnstakeRequests(i, signer.address);
            if (requests.length > 0) {
                console.log("  Unstake requests:");
                for (let j = 0; j < requests.length; j++) {
                    if (requests[j].amount > 0) {
                        console.log(`    ${j}: ${ethers.formatEther(requests[j].amount)} (unlock block: ${requests[j].unlockBlock})`);
                    }
                }
            }
        }
    }

    // Display token balances
    console.log("\n=== Token Balances ===");
    console.log("ETH balance:", ethers.formatEther(await signer.provider.getBalance(signer.address)));
    console.log("META balance:", ethers.formatEther(await metaNodeToken.balanceOf(signer.address)));
    console.log("META in stake contract:", ethers.formatEther(await metaNodeToken.balanceOf(stakeContractAddress)));

    // Interactive menu
    console.log("\n=== Available Actions ===");
    console.log("1. Stake ETH");
    console.log("2. Stake META tokens");
    console.log("3. Unstake from pool");
    console.log("4. Withdraw unstaked tokens");
    console.log("5. Claim rewards");
    console.log("6. Emergency withdraw");
    console.log("7. Exit");

    // Note: In a real script, you would implement readline interface for user input
    // For now, we'll just show the available functions
    console.log("\nTo interact with the contract, you can call these functions:");
    console.log("- stakeContract.stake(poolId, amount, { value: ethAmount })");
    console.log("- stakeContract.unstake(poolId, amount)");
    console.log("- stakeContract.withdraw(poolId, requestIndex)");
    console.log("- stakeContract.claimReward(poolId)");
    console.log("- stakeContract.emergencyWithdraw(poolId)");

    // Example: Stake 0.1 ETH to pool 0
    // await stakeContract.stake(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });

    // Example: Claim rewards from pool 0
    // await stakeContract.claimReward(0);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });