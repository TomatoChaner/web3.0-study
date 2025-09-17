const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("StakeContract", function () {
    let MetaNodeToken;
    let StakeContract;
    let metaNodeToken;
    let stakeContract;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    const TOKEN_NAME = "MetaNode Token";
    const TOKEN_SYMBOL = "MNT";
    const INITIAL_SUPPLY = ethers.parseEther("1000000");
    const MIN_STAKE_AMOUNT = ethers.parseEther("0.01");
    const MAX_STAKE_AMOUNT = ethers.parseEther("100");

    beforeEach(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        // Deploy MetaNodeToken
        MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
        metaNodeToken = await MetaNodeToken.deploy(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);

        // Deploy StakeContract
        StakeContract = await ethers.getContractFactory("StakeContract");
        stakeContract = await StakeContract.deploy(metaNodeToken.target);

        // Grant MINTER_ROLE to StakeContract
        await metaNodeToken.grantMinterRole(stakeContract.target);
    });

    describe("Deployment", function () {
        it("Should set the correct reward token", async function () {
            expect(await stakeContract.rewardToken()).to.equal(metaNodeToken.target);
        });

        it("Should set correct constants", async function () {
            expect(await stakeContract.MIN_STAKE_AMOUNT()).to.equal(MIN_STAKE_AMOUNT);
            expect(await stakeContract.MAX_STAKE_AMOUNT()).to.equal(MAX_STAKE_AMOUNT);
            expect(await stakeContract.REWARD_RATE()).to.equal(100); // 1% per day
        });

        it("Should grant roles to deployer", async function () {
            const DEFAULT_ADMIN_ROLE = await stakeContract.DEFAULT_ADMIN_ROLE();
            const ADMIN_ROLE = await stakeContract.ADMIN_ROLE();
            const OPERATOR_ROLE = await stakeContract.OPERATOR_ROLE();

            expect(await stakeContract.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;
        expect(await stakeContract.hasRole(ADMIN_ROLE, owner.address)).to.be.true;
        expect(await stakeContract.hasRole(OPERATOR_ROLE, owner.address)).to.be.true;
        });

        it("Should initialize with zero total staked", async function () {
            expect(await stakeContract.totalStaked()).to.equal(0);
            expect(await stakeContract.totalRewardsDistributed()).to.equal(0);
        });

        it("Should revert with invalid reward token address", async function () {
            await expect(
                StakeContract.deploy(ethers.ZeroAddress)
            ).to.be.revertedWith("Invalid reward token address");
        });
    });

    describe("Staking", function () {
        it("Should allow user to stake ETH", async function () {
            const stakeAmount = ethers.parseEther("1.0");
            
            await expect(stakeContract.connect(addr1).stake({ value: stakeAmount }))
                .to.emit(stakeContract, "Staked")
                .withArgs(addr1.address, stakeAmount, await time.latest() + 1);

            const stakeInfo = await stakeContract.getUserStakeInfo(addr1.address);
            expect(stakeInfo.amount).to.equal(stakeAmount);
            expect(stakeInfo.active).to.be.true;
            expect(await stakeContract.totalStaked()).to.equal(stakeAmount);
        });

        it("Should not allow staking below minimum amount", async function () {
            const stakeAmount = ethers.parseEther("0.005"); // Below minimum
            
            await expect(
                stakeContract.connect(addr1).stake({ value: stakeAmount })
            ).to.be.revertedWith("Stake amount too low");
        });

        it("Should not allow staking above maximum amount", async function () {
            const stakeAmount = ethers.parseEther("101"); // Above maximum
            
            await expect(
                stakeContract.connect(addr1).stake({ value: stakeAmount })
            ).to.be.revertedWith("Stake amount exceeds maximum");
        });

        it("Should allow multiple stakes from same user", async function () {
            const firstStake = ethers.parseEther("1.0");
            const secondStake = ethers.parseEther("0.5");
            
            await stakeContract.connect(addr1).stake({ value: firstStake });
            await stakeContract.connect(addr1).stake({ value: secondStake });

            const stakeInfo = await stakeContract.getUserStakeInfo(addr1.address);
            expect(stakeInfo.amount).to.equal(firstStake + secondStake);
        });

        it("Should not allow staking when paused", async function () {
            await stakeContract.pause();
            
            await expect(
                stakeContract.connect(addr1).stake({ value: ethers.parseEther("1.0") })
            ).to.be.revertedWith("Pausable: paused");
        });
    });

    describe("Rewards Calculation", function () {
        beforeEach(async function () {
            // Stake 1 ETH
            await stakeContract.connect(addr1).stake({ value: ethers.parseEther("1.0") });
        });

        it("Should calculate pending rewards correctly", async function () {
            // Advance time by 1 day
            await time.increase(86400); // 1 day in seconds
            
            const pendingRewards = await stakeContract.getPendingRewards(addr1.address);
            const expectedRewards = (ethers.parseEther("1.0") * 100n) / 10000n; // 1% of 1 ETH
            
            expect(pendingRewards).to.be.closeTo(expectedRewards, ethers.parseEther("0.001"));
        });

        it("Should return zero rewards for non-stakers", async function () {
            const pendingRewards = await stakeContract.getPendingRewards(addr2.address);
            expect(pendingRewards).to.equal(0);
        });

        it("Should accumulate rewards over time", async function () {
            // Advance time by 2 days
            await time.increase(86400 * 2);
            
            const pendingRewards = await stakeContract.getPendingRewards(addr1.address);
            const expectedRewards = (ethers.parseEther("1.0") * 200n) / 10000n; // 2% of 1 ETH
            
            expect(pendingRewards).to.be.closeTo(expectedRewards, ethers.parseEther("0.001"));
        });
    });

    describe("Claiming Rewards", function () {
        beforeEach(async function () {
            await stakeContract.connect(addr1).stake({ value: ethers.parseEther("1.0") });
            await time.increase(86400); // Advance 1 day
        });

        it("Should allow user to claim rewards", async function () {
            const initialTokenBalance = await metaNodeToken.balanceOf(addr1.address);
            
            await expect(stakeContract.connect(addr1).claimRewards())
                .to.emit(stakeContract, "RewardsClaimed");

            const finalTokenBalance = await metaNodeToken.balanceOf(addr1.address);
            expect(finalTokenBalance).to.be.gt(initialTokenBalance);
        });

        it("Should reset accumulated rewards after claiming", async function () {
            await stakeContract.connect(addr1).claimRewards();
            
            const stakeInfo = await stakeContract.getUserStakeInfo(addr1.address);
            expect(stakeInfo.accumulatedRewards).to.equal(0);
        });

        it("Should not allow claiming with no active stake", async function () {
            await expect(
                stakeContract.connect(addr2).claimRewards()
            ).to.be.revertedWith("No active stake found");
        });

        it("Should not allow claiming when paused", async function () {
            await stakeContract.pause();
            
            await expect(
                stakeContract.connect(addr1).claimRewards()
            ).to.be.revertedWith("Pausable: paused");
        });
    });

    describe("Unstaking", function () {
        beforeEach(async function () {
            await stakeContract.connect(addr1).stake({ value: ethers.parseEther("2.0") });
            await time.increase(86400); // Advance 1 day for rewards
        });

        it("Should allow partial unstaking", async function () {
            const unstakeAmount = ethers.parseEther("1.0");
            const initialBalance = await ethers.provider.getBalance(addr1.address);
            
            const tx = await stakeContract.connect(addr1).unstake(unstakeAmount);
            const receipt = await tx.wait();
            const gasUsed = BigInt(receipt.gasUsed) * BigInt(receipt.effectiveGasPrice || receipt.gasPrice || 0);
            
            const finalBalance = await ethers.provider.getBalance(addr1.address);
            const expectedBalance = BigInt(initialBalance) + unstakeAmount - gasUsed;
            
            expect(finalBalance).to.be.closeTo(expectedBalance, ethers.parseEther("0.001"));
            
            const stakeInfo = await stakeContract.getUserStakeInfo(addr1.address);
            expect(stakeInfo.amount).to.equal(ethers.parseEther("1.0"));
            expect(stakeInfo.active).to.be.true;
        });

        it("Should allow full unstaking", async function () {
            await expect(stakeContract.connect(addr1).unstake(0))
                .to.emit(stakeContract, "Unstaked");

            const stakeInfo = await stakeContract.getUserStakeInfo(addr1.address);
            expect(stakeInfo.amount).to.equal(0);
            expect(stakeInfo.active).to.be.false;
        });

        it("Should transfer rewards when unstaking", async function () {
            const initialTokenBalance = await metaNodeToken.balanceOf(addr1.address);
            
            await stakeContract.connect(addr1).unstake(0); // Full unstake
            
            const finalTokenBalance = await metaNodeToken.balanceOf(addr1.address);
            expect(finalTokenBalance).to.be.gt(initialTokenBalance);
        });

        it("Should not allow unstaking more than staked", async function () {
            const excessiveAmount = ethers.parseEther("3.0");
            
            await expect(
                stakeContract.connect(addr1).unstake(excessiveAmount)
            ).to.be.revertedWith("Insufficient staked amount");
        });

        it("Should not allow unstaking with no active stake", async function () {
            await expect(
                stakeContract.connect(addr2).unstake(ethers.parseEther("1.0"))
            ).to.be.revertedWith("No active stake found");
        });
    });

    describe("Emergency Withdraw", function () {
        beforeEach(async function () {
            await stakeContract.connect(addr1).stake({ value: ethers.parseEther("1.0") });
        });

        it("Should not allow emergency withdraw when disabled", async function () {
            await expect(
                stakeContract.connect(addr1).emergencyWithdraw()
            ).to.be.revertedWith("Emergency withdraw not enabled");
        });

        it("Should allow emergency withdraw when enabled", async function () {
            await stakeContract.toggleEmergencyWithdraw(true);
            
            const initialBalance = await ethers.provider.getBalance(addr1.address);
            const tx = await stakeContract.connect(addr1).emergencyWithdraw();
            const receipt = await tx.wait();
            const gasUsed = BigInt(receipt.gasUsed) * BigInt(receipt.effectiveGasPrice || receipt.gasPrice || 0);
            
            const finalBalance = await ethers.provider.getBalance(addr1.address);
            const expectedBalance = BigInt(initialBalance) + ethers.parseEther("1.0") - gasUsed;
            
            expect(finalBalance).to.be.closeTo(expectedBalance, ethers.parseEther("0.001"));
            
            const stakeInfo = await stakeContract.getUserStakeInfo(addr1.address);
            expect(stakeInfo.active).to.be.false;
        });

        it("Should not transfer rewards during emergency withdraw", async function () {
            await time.increase(86400); // Advance 1 day for rewards
            
            // Get pending rewards before emergency mode
            const pendingRewards = await stakeContract.getPendingRewards(addr1.address);
            expect(pendingRewards).to.be.greaterThan(0); // Ensure there were rewards to claim
            
            await stakeContract.toggleEmergencyWithdraw(true);

            // In emergency mode, claiming rewards should be reverted
            await expect(
                stakeContract.connect(addr1).claimRewards()
            ).to.be.revertedWith("Cannot claim rewards during emergency mode");
        });
    });

    describe("Admin Functions", function () {
        it("Should allow admin to toggle emergency withdraw", async function () {
            await expect(stakeContract.toggleEmergencyWithdraw(true))
                .to.emit(stakeContract, "EmergencyWithdrawToggled")
                .withArgs(true);

            expect(await stakeContract.emergencyWithdrawEnabled()).to.be.true;
        });

        it("Should not allow non-admin to toggle emergency withdraw", async function () {
            await expect(
                stakeContract.connect(addr1).toggleEmergencyWithdraw(true)
            ).to.be.reverted;
        });

        it("Should allow admin to pause contract", async function () {
            await stakeContract.pause();
            expect(await stakeContract.paused()).to.be.true;
        });

        it("Should allow admin to withdraw contract balance", async function () {
            // Add some extra ETH to contract (not from staking)
            await owner.sendTransaction({
                to: stakeContract.target,
                value: ethers.parseEther("1.0")
            });

            const initialBalance = await ethers.provider.getBalance(owner.address);
            const tx = await stakeContract.withdrawContractBalance(0);
            const receipt = await tx.wait();
            const gasUsed = BigInt(receipt.gasUsed) * BigInt(receipt.effectiveGasPrice || receipt.gasPrice || 0);
            
            const finalBalance = await ethers.provider.getBalance(owner.address);
            const expectedBalance = BigInt(initialBalance) + ethers.parseEther("1.0") - gasUsed;
            
            expect(finalBalance).to.be.closeTo(expectedBalance, ethers.parseEther("0.001"));
        });

        it("Should not allow withdrawing staked funds", async function () {
            await stakeContract.connect(addr1).stake({ value: ethers.parseEther("1.0") });
            
            await expect(
                stakeContract.withdrawContractBalance(0)
            ).to.be.revertedWith("Cannot withdraw staked funds");
        });
    });

    describe("Contract Statistics", function () {
        it("Should return correct contract stats", async function () {
            await stakeContract.connect(addr1).stake({ value: ethers.parseEther("1.0") });
            await stakeContract.connect(addr2).stake({ value: ethers.parseEther("0.5") });
            
            const stats = await stakeContract.getContractStats();
            expect(stats[0]).to.equal(ethers.parseEther("1.5")); // totalStaked
            expect(stats[1]).to.equal(0); // totalRewardsDistributed (no claims yet)
            expect(stats[2]).to.equal(ethers.parseEther("1.5")); // contractBalance
        });
    });
});