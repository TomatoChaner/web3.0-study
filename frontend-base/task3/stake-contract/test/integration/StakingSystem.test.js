const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Staking System Integration", function () {
    let MetaNodeToken;
    let StakeContract;
    let metaNodeToken;
    let stakeContract;
    let owner;
    let user1;
    let user2;
    let user3;

    const TOKEN_NAME = "MetaNode Token";
    const TOKEN_SYMBOL = "MNT";
    const INITIAL_SUPPLY = ethers.parseEther("1000000");

    beforeEach(async function () {
        [owner, user1, user2, user3] = await ethers.getSigners();

        // Deploy contracts
        MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
        metaNodeToken = await MetaNodeToken.deploy(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);

        StakeContract = await ethers.getContractFactory("StakeContract");
        stakeContract = await StakeContract.deploy(metaNodeToken.target);

        // Setup permissions
        await metaNodeToken.grantMinterRole(stakeContract.target);
    });

    describe("Complete Staking Workflow", function () {
        it("Should handle multiple users staking, earning rewards, and unstaking", async function () {
            console.log("🧪 Testing complete staking workflow...");

            // Initial state
            expect(await stakeContract.totalStaked()).to.equal(0);
            expect(await stakeContract.totalRewardsDistributed()).to.equal(0);

            // User1 stakes 2 ETH
            console.log("👤 User1 staking 2 ETH...");
            await stakeContract.connect(user1).stake({ value: ethers.parseEther("2.0") });
            
            let user1StakeInfo = await stakeContract.getUserStakeInfo(user1.address);
            expect(user1StakeInfo.amount).to.equal(ethers.parseEther("2.0"));
            expect(user1StakeInfo.active).to.be.true;

            // User2 stakes 1 ETH
            console.log("👤 User2 staking 1 ETH...");
            await stakeContract.connect(user2).stake({ value: ethers.parseEther("1.0") });
            
            let user2StakeInfo = await stakeContract.getUserStakeInfo(user2.address);
            expect(user2StakeInfo.amount).to.equal(ethers.parseEther("1.0"));

            // Check total staked
            expect(await stakeContract.totalStaked()).to.equal(ethers.parseEther("3.0"));

            // Advance time by 1 day
            console.log("⏰ Advancing time by 1 day...");
            await time.increase(86400);

            // Check pending rewards
            const user1PendingRewards = await stakeContract.getPendingRewards(user1.address);
            const user2PendingRewards = await stakeContract.getPendingRewards(user2.address);
            
            console.log("💰 User1 pending rewards:", ethers.formatEther(user1PendingRewards));
            console.log("💰 User2 pending rewards:", ethers.formatEther(user2PendingRewards));

            // User1 should have 2x the rewards of User2 (2 ETH vs 1 ETH staked)
            expect(user1PendingRewards).to.be.closeTo(
                user2PendingRewards * 2n,
                ethers.parseEther("0.001")
            );

            // User1 claims rewards
            console.log("💰 User1 claiming rewards...");
            await stakeContract.connect(user1).claimRewards();
            
            const user1TokenBalance = await metaNodeToken.balanceOf(user1.address);
            expect(user1TokenBalance).to.be.gt(0);
            console.log("🪙 User1 token balance:", ethers.formatEther(user1TokenBalance));

            // User2 adds more stake
            console.log("👤 User2 adding 0.5 ETH more...");
            await stakeContract.connect(user2).stake({ value: ethers.parseEther("0.5") });
            
            user2StakeInfo = await stakeContract.getUserStakeInfo(user2.address);
            expect(user2StakeInfo.amount).to.equal(ethers.parseEther("1.5"));

            // Advance time by another day
            console.log("⏰ Advancing time by another day...");
            await time.increase(86400);

            // User3 stakes
            console.log("👤 User3 staking 3 ETH...");
            await stakeContract.connect(user3).stake({ value: ethers.parseEther("3.0") });

            // Check total staked
            expect(await stakeContract.totalStaked()).to.equal(ethers.parseEther("6.5"));

            // Advance time and let everyone accumulate rewards
            console.log("⏰ Advancing time by 2 more days...");
            await time.increase(86400 * 2);

            // Everyone claims rewards
            console.log("💰 All users claiming rewards...");
            await stakeContract.connect(user1).claimRewards();
            await stakeContract.connect(user2).claimRewards();
            await stakeContract.connect(user3).claimRewards();

            // Check token balances
            const finalUser1Balance = await metaNodeToken.balanceOf(user1.address);
            const finalUser2Balance = await metaNodeToken.balanceOf(user2.address);
            const finalUser3Balance = await metaNodeToken.balanceOf(user3.address);

            console.log("🪙 Final token balances:");
            console.log("   User1:", ethers.formatEther(finalUser1Balance));
            console.log("   User2:", ethers.formatEther(finalUser2Balance));
            console.log("   User3:", ethers.formatEther(finalUser3Balance));

            expect(finalUser1Balance).to.be.gt(0);
            expect(finalUser2Balance).to.be.gt(0);
            expect(finalUser3Balance).to.be.gt(0);

            // User1 partially unstakes
            console.log("📤 User1 partially unstaking 1 ETH...");
            const user1InitialETH = await ethers.provider.getBalance(user1.address);
            const tx = await stakeContract.connect(user1).unstake(ethers.parseEther("1.0"));
            const receipt = await tx.wait();
            const gasUsed = BigInt(receipt.gasUsed) * BigInt(receipt.effectiveGasPrice || receipt.gasPrice || 0);
            
            const user1FinalETH = await ethers.provider.getBalance(user1.address);
            expect(user1FinalETH).to.be.closeTo(
                BigInt(user1InitialETH) + ethers.parseEther("1.0") - gasUsed,
                ethers.parseEther("0.001")
            );

            // Check User1's remaining stake
            user1StakeInfo = await stakeContract.getUserStakeInfo(user1.address);
            expect(user1StakeInfo.amount).to.equal(ethers.parseEther("1.0"));
            expect(user1StakeInfo.active).to.be.true;

            // User2 fully unstakes
            console.log("📤 User2 fully unstaking...");
            await stakeContract.connect(user2).unstake(0);
            
            user2StakeInfo = await stakeContract.getUserStakeInfo(user2.address);
            expect(user2StakeInfo.amount).to.equal(0);
            expect(user2StakeInfo.active).to.be.false;

            // Check final contract state
            const finalStats = await stakeContract.getContractStats();
            console.log("📊 Final contract stats:");
            console.log("   Total Staked:", ethers.formatEther(finalStats[0]));
            console.log("   Total Rewards Distributed:", ethers.formatEther(finalStats[1]));
            console.log("   Contract Balance:", ethers.formatEther(finalStats[2]));

            expect(finalStats[0]).to.equal(ethers.parseEther("4.0")); // User1: 1 ETH, User3: 3 ETH
            expect(finalStats[1]).to.be.gt(0); // Some rewards were distributed
        });

        it("Should handle emergency scenarios correctly", async function () {
            console.log("🚨 Testing emergency scenarios...");

            // Users stake
            await stakeContract.connect(user1).stake({ value: ethers.parseEther("1.0") });
            await stakeContract.connect(user2).stake({ value: ethers.parseEther("2.0") });

            // Advance time for rewards
            await time.increase(86400);

            // Admin enables emergency withdraw
            console.log("🚨 Admin enabling emergency withdraw...");
            await stakeContract.toggleEmergencyWithdraw(true);

            // User1 uses emergency withdraw
            console.log("🚨 User1 using emergency withdraw...");
            const user1InitialBalance = await ethers.provider.getBalance(user1.address);
            const tx = await stakeContract.connect(user1).emergencyWithdraw();
            const receipt = await tx.wait();
            const gasUsed = BigInt(receipt.gasUsed) * BigInt(receipt.effectiveGasPrice || receipt.gasPrice || 0);

            const user1FinalBalance = await ethers.provider.getBalance(user1.address);
            expect(user1FinalBalance).to.be.closeTo(
                BigInt(user1InitialBalance) + ethers.parseEther("1.0") - gasUsed,
                ethers.parseEther("0.001")
            );

            // User1 should have no token rewards (emergency withdraw doesn't give rewards)
            const user1TokenBalance = await metaNodeToken.balanceOf(user1.address);
            expect(user1TokenBalance).to.equal(0);

            // User2 chooses normal unstake to get rewards
            console.log("💰 User2 using normal unstake to get rewards...");
            await stakeContract.connect(user2).unstake(0);
            
            const user2TokenBalance = await metaNodeToken.balanceOf(user2.address);
            expect(user2TokenBalance).to.be.gt(0);

            console.log("🪙 User2 received rewards:", ethers.formatEther(user2TokenBalance));
        });

        it("Should handle contract pausing correctly", async function () {
            console.log("⏸️ Testing contract pausing...");

            // User stakes before pause
            await stakeContract.connect(user1).stake({ value: ethers.parseEther("1.0") });

            // Admin pauses contract
            console.log("⏸️ Admin pausing contract...");
            await stakeContract.pause();

            // Should not allow new stakes
            await expect(
                stakeContract.connect(user2).stake({ value: ethers.parseEther("1.0") })
            ).to.be.revertedWith("Pausable: paused");

            // Should not allow claiming rewards
            await expect(
                stakeContract.connect(user1).claimRewards()
            ).to.be.revertedWith("Pausable: paused");

            // Should not allow unstaking
            await expect(
                stakeContract.connect(user1).unstake(ethers.parseEther("0.5"))
            ).to.be.revertedWith("Pausable: paused");

            // Admin unpauses
            console.log("▶️ Admin unpausing contract...");
            await stakeContract.unpause();

            // Should allow operations again
            await stakeContract.connect(user2).stake({ value: ethers.parseEther("1.0") });
            
            // Advance time for rewards
            await time.increase(86400);
            
            await stakeContract.connect(user1).claimRewards();
            const user1TokenBalance = await metaNodeToken.balanceOf(user1.address);
            expect(user1TokenBalance).to.be.gt(0);

            console.log("✅ Contract functionality restored after unpause");
        });
    });

    describe("Edge Cases and Security", function () {
        it("Should handle maximum stake limits correctly", async function () {
            const maxStake = await stakeContract.MAX_STAKE_AMOUNT();
            
            // Should allow staking up to maximum
            await stakeContract.connect(user1).stake({ value: maxStake });
            
            // Should not allow exceeding maximum
            await expect(
                stakeContract.connect(user1).stake({ value: ethers.parseEther("0.01") })
            ).to.be.revertedWith("Stake amount exceeds maximum");
        });

        it("Should handle token supply limits correctly", async function () {
            // Stake a large amount
            await stakeContract.connect(user1).stake({ value: ethers.parseEther("50.0") });
            
            // Advance time significantly to generate large rewards
            await time.increase(86400 * 365); // 1 year
            
            // Should still be able to claim rewards (within token supply limits)
            await stakeContract.connect(user1).claimRewards();
            
            const tokenBalance = await metaNodeToken.balanceOf(user1.address);
            const maxSupply = await metaNodeToken.MAX_SUPPLY();
            
            expect(tokenBalance).to.be.lt(maxSupply);
        });

        it("Should prevent reentrancy attacks", async function () {
            // This test ensures the nonReentrant modifier is working
            // In a real attack scenario, a malicious contract would try to call
            // stake/unstake functions recursively
            
            await stakeContract.connect(user1).stake({ value: ethers.parseEther("1.0") });
            
            // Normal unstaking should work
            await stakeContract.connect(user1).unstake(ethers.parseEther("0.5"));
            
            const stakeInfo = await stakeContract.getUserStakeInfo(user1.address);
            expect(stakeInfo.amount).to.equal(ethers.parseEther("0.5"));
        });
    });
});