const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("MetaNodeStake", function () {
    // Fixture for deploying contracts
    async function deployContractsFixture() {
        const [owner, user1, user2, user3] = await ethers.getSigners();

        // Deploy MetaNode token (mock ERC20)
        const MetaNodeToken = await ethers.getContractFactory("MockERC20");
        const metaNodeToken = await MetaNodeToken.deploy("MetaNode Token", "META", ethers.parseEther("1000000"));

        // Deploy test token for staking
        const TestToken = await ethers.getContractFactory("MockERC20");
        const testToken = await TestToken.deploy("Test Token", "TEST", ethers.parseEther("1000000"));

        // Deploy MetaNodeStake contract using UUPS proxy
        const MetaNodeStake = await ethers.getContractFactory("MetaNodeStake");
        const rewardPerBlock = ethers.parseEther("1"); // 1 META per block
        
        const stakeContract = await upgrades.deployProxy(MetaNodeStake, [
            await metaNodeToken.getAddress(),
            rewardPerBlock,
            owner.address
        ], { 
            initializer: 'initialize',
            kind: 'uups',
            unsafeAllow: ['constructor']
        });

        // Transfer some tokens to users for testing
        await testToken.transfer(user1.address, ethers.parseEther("1000"));
        await testToken.transfer(user2.address, ethers.parseEther("1000"));
        await testToken.transfer(user3.address, ethers.parseEther("1000"));

        // Transfer reward tokens to stake contract
        await metaNodeToken.transfer(await stakeContract.getAddress(), ethers.parseEther("100000"));

        return {
            stakeContract,
            metaNodeToken,
            testToken,
            owner,
            user1,
            user2,
            user3,
            rewardPerBlock
        };
    }

    describe("Deployment and Initialization", function () {
        it("Should initialize correctly", async function () {
            const { stakeContract, metaNodeToken, owner, rewardPerBlock } = await loadFixture(deployContractsFixture);

            expect(await stakeContract.metaNodeToken()).to.equal(await metaNodeToken.getAddress());
            expect(await stakeContract.rewardPerBlock()).to.equal(rewardPerBlock);
            expect(await stakeContract.hasRole(await stakeContract.ADMIN_ROLE(), owner.address)).to.be.true;
        });

        it("Should not allow double initialization", async function () {
            const { stakeContract, metaNodeToken, owner, rewardPerBlock } = await loadFixture(deployContractsFixture);

            await expect(
                stakeContract.initialize(
                    await metaNodeToken.getAddress(),
                    rewardPerBlock,
                    owner.address
                )
            ).to.be.revertedWithCustomError(stakeContract, "InvalidInitialization");
        });
    });

    describe("Pool Management", function () {
        it("Should add a new pool", async function () {
            const { stakeContract, testToken, owner } = await loadFixture(deployContractsFixture);

            const poolWeight = 100;
            const minDepositAmount = ethers.parseEther("1");
            const unstakeLockedBlocks = 100;

            await expect(
                stakeContract.connect(owner).addPool(
                    await testToken.getAddress(),
                    poolWeight,
                    minDepositAmount,
                    unstakeLockedBlocks
                )
            ).to.emit(stakeContract, "PoolAdded")
             .withArgs(0, await testToken.getAddress(), poolWeight, minDepositAmount, unstakeLockedBlocks);

            expect(await stakeContract.poolLength()).to.equal(1);
            expect(await stakeContract.totalPoolWeight()).to.equal(poolWeight);

            const pool = await stakeContract.getPool(0);
            expect(pool.stTokenAddress).to.equal(await testToken.getAddress());
            expect(pool.poolWeight).to.equal(poolWeight);
            expect(pool.minDepositAmount).to.equal(minDepositAmount);
            expect(pool.unstakeLockedBlocks).to.equal(unstakeLockedBlocks);
        });

        it("Should add ETH pool", async function () {
            const { stakeContract, owner } = await loadFixture(deployContractsFixture);

            const ETH_ADDRESS = "0x0000000000000000000000000000000000000000";
            const poolWeight = 200;
            const minDepositAmount = ethers.parseEther("0.1");
            const unstakeLockedBlocks = 200;

            await stakeContract.connect(owner).addPool(
                ETH_ADDRESS,
                poolWeight,
                minDepositAmount,
                unstakeLockedBlocks
            );

            const pool = await stakeContract.getPool(0);
            expect(pool.stTokenAddress).to.equal(ETH_ADDRESS);
        });

        it("Should update pool parameters", async function () {
            const { stakeContract, testToken, owner } = await loadFixture(deployContractsFixture);

            // Add pool first
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            // Update pool
            const newWeight = 200;
            const newMinDeposit = ethers.parseEther("2");
            const newLockBlocks = 200;

            await expect(
                stakeContract.connect(owner).updatePool(0, newWeight, newMinDeposit, newLockBlocks)
            ).to.emit(stakeContract, "PoolUpdated")
             .withArgs(0, newWeight, newMinDeposit, newLockBlocks);

            const pool = await stakeContract.getPool(0);
            expect(pool.poolWeight).to.equal(newWeight);
            expect(pool.minDepositAmount).to.equal(newMinDeposit);
            expect(pool.unstakeLockedBlocks).to.equal(newLockBlocks);
        });

        it("Should not allow non-admin to add pool", async function () {
            const { stakeContract, testToken, user1 } = await loadFixture(deployContractsFixture);

            await expect(
                stakeContract.connect(user1).addPool(
                    await testToken.getAddress(),
                    100,
                    ethers.parseEther("1"),
                    100
                )
            ).to.be.revertedWith("MetaNodeStake: Caller is not admin");
        });
    });

    describe("Staking", function () {
        it("Should stake ERC20 tokens", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            // Add pool
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            // Approve tokens
            const stakeAmount = ethers.parseEther("10");
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stakeAmount);

            // Stake tokens
            await expect(
                stakeContract.connect(user1).stake(0, stakeAmount)
            ).to.emit(stakeContract, "Staked")
             .withArgs(user1.address, 0, stakeAmount);

            const user = await stakeContract.getUser(0, user1.address);
            expect(user.stAmount).to.equal(stakeAmount);

            const pool = await stakeContract.getPool(0);
            expect(pool.stTokenAmount).to.equal(stakeAmount);
        });

        it("Should stake ETH", async function () {
            const { stakeContract, owner, user1 } = await loadFixture(deployContractsFixture);

            const ETH_ADDRESS = "0x0000000000000000000000000000000000000000";

            // Add ETH pool
            await stakeContract.connect(owner).addPool(
                ETH_ADDRESS,
                100,
                ethers.parseEther("0.1"),
                100
            );

            // Stake ETH
            const stakeAmount = ethers.parseEther("1");
            await expect(
                stakeContract.connect(user1).stake(0, stakeAmount, { value: stakeAmount })
            ).to.emit(stakeContract, "Staked")
             .withArgs(user1.address, 0, stakeAmount);

            const user = await stakeContract.getUser(0, user1.address);
            expect(user.stAmount).to.equal(stakeAmount);
        });

        it("Should not allow staking below minimum", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            const minDeposit = ethers.parseEther("10");
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                minDeposit,
                100
            );

            const stakeAmount = ethers.parseEther("5"); // Below minimum
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stakeAmount);

            await expect(
                stakeContract.connect(user1).stake(0, stakeAmount)
            ).to.be.revertedWith("MetaNodeStake: Amount below minimum");
        });
    });

    describe("Unstaking and Withdrawal", function () {
        it("Should unstake tokens", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            // Setup pool and stake
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            const stakeAmount = ethers.parseEther("10");
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stakeAmount);
            await stakeContract.connect(user1).stake(0, stakeAmount);

            // Unstake half
            const unstakeAmount = ethers.parseEther("5");
            const currentBlock = await ethers.provider.getBlockNumber();

            await expect(
                stakeContract.connect(user1).unstake(0, unstakeAmount)
            ).to.emit(stakeContract, "Unstaked")
             .withArgs(user1.address, 0, unstakeAmount, currentBlock + 1 + 100);

            const user = await stakeContract.getUser(0, user1.address);
            expect(user.stAmount).to.equal(stakeAmount - unstakeAmount);

            const requests = await stakeContract.getUserUnstakeRequests(0, user1.address);
            expect(requests.length).to.equal(1);
            expect(requests[0].amount).to.equal(unstakeAmount);
        });

        it("Should withdraw after lock period", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            // Setup pool and stake
            const lockBlocks = 10;
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                lockBlocks
            );

            const stakeAmount = ethers.parseEther("10");
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stakeAmount);
            await stakeContract.connect(user1).stake(0, stakeAmount);

            // Unstake
            const unstakeAmount = ethers.parseEther("5");
            await stakeContract.connect(user1).unstake(0, unstakeAmount);

            // Try to withdraw before lock period ends
            await expect(
                stakeContract.connect(user1).withdraw(0, 0)
            ).to.be.revertedWith("MetaNodeStake: Tokens still locked");

            // Mine blocks to pass lock period
            await time.advanceBlockTo(await ethers.provider.getBlockNumber() + lockBlocks);

            // Now withdraw should work
            const balanceBefore = await testToken.balanceOf(user1.address);
            await expect(
                stakeContract.connect(user1).withdraw(0, 0)
            ).to.emit(stakeContract, "Withdrawn")
             .withArgs(user1.address, 0, unstakeAmount);

            const balanceAfter = await testToken.balanceOf(user1.address);
            expect(balanceAfter - balanceBefore).to.equal(unstakeAmount);
        });

        it("Should not allow double withdrawal", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            // Setup and stake
            const lockBlocks = 10;
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                lockBlocks
            );

            const stakeAmount = ethers.parseEther("10");
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stakeAmount);
            await stakeContract.connect(user1).stake(0, stakeAmount);

            // Unstake and wait
            await stakeContract.connect(user1).unstake(0, ethers.parseEther("5"));
            await time.advanceBlockTo(await ethers.provider.getBlockNumber() + lockBlocks);

            // First withdrawal
            await stakeContract.connect(user1).withdraw(0, 0);

            // Second withdrawal should fail
            await expect(
                stakeContract.connect(user1).withdraw(0, 0)
            ).to.be.revertedWith("MetaNodeStake: Request already processed");
        });
    });

    describe("Rewards", function () {
        it("Should calculate pending rewards correctly", async function () {
            const { stakeContract, testToken, owner, user1, rewardPerBlock } = await loadFixture(deployContractsFixture);

            // Add pool
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100, // 100% of rewards
                ethers.parseEther("1"),
                100
            );

            // Stake tokens
            const stakeAmount = ethers.parseEther("10");
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stakeAmount);
            await stakeContract.connect(user1).stake(0, stakeAmount);

            // Mine some blocks
            const blocksBefore = await ethers.provider.getBlockNumber();
            await time.advanceBlockTo(blocksBefore + 10);

            // Check pending rewards
            const pending = await stakeContract.pendingReward(0, user1.address);
            expect(pending).to.be.gt(0);
        });

        it("Should claim rewards", async function () {
            const { stakeContract, testToken, metaNodeToken, owner, user1 } = await loadFixture(deployContractsFixture);

            // Add pool
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            // Stake tokens
            const stakeAmount = ethers.parseEther("10");
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stakeAmount);
            await stakeContract.connect(user1).stake(0, stakeAmount);

            // Mine blocks and claim
            await time.advanceBlockTo(await ethers.provider.getBlockNumber() + 10);

            const balanceBefore = await metaNodeToken.balanceOf(user1.address);

            const tx = await stakeContract.connect(user1).claimReward(0);
            const receipt = await tx.wait();
            
            // Get the actual reward amount from the event
            const event = receipt.logs.find(log => {
                try {
                    const parsed = stakeContract.interface.parseLog(log);
                    return parsed.name === "RewardClaimed";
                } catch {
                    return false;
                }
            });
            
            expect(event).to.not.be.undefined;
            const actualReward = stakeContract.interface.parseLog(event).args[2];

            const balanceAfter = await metaNodeToken.balanceOf(user1.address);
            expect(balanceAfter - balanceBefore).to.equal(actualReward);
        });

        it("Should distribute rewards proportionally among multiple users", async function () {
            const { stakeContract, testToken, owner, user1, user2 } = await loadFixture(deployContractsFixture);

            // Add pool
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            // Both users stake at the same time
            const stake1 = ethers.parseEther("10");
            const stake2 = ethers.parseEther("20");
            
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stake1);
            await testToken.connect(user2).approve(await stakeContract.getAddress(), stake2);
            
            // Stake in the same block
            await stakeContract.connect(user1).stake(0, stake1);
            await stakeContract.connect(user2).stake(0, stake2);

            // Mine blocks after both users have staked
            await time.advanceBlockTo(await ethers.provider.getBlockNumber() + 10);

            const pending1 = await stakeContract.pendingReward(0, user1.address);
            const pending2 = await stakeContract.pendingReward(0, user2.address);

            // Both users should have rewards
            expect(pending1).to.be.gt(0);
            expect(pending2).to.be.gt(0);
            
            // User2 should have approximately 2x more rewards than user1 (since they have 2x stake)
            // Allow for some variance due to block timing
            const ratio = Number(pending2 * 100n / pending1);
            expect(ratio).to.be.gte(150); // At least 1.5x
            expect(ratio).to.be.lte(250); // At most 2.5x
        });
    });

    describe("Emergency Functions", function () {
        it("Should allow emergency withdraw", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            // Setup and stake
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            const stakeAmount = ethers.parseEther("10");
            await testToken.connect(user1).approve(await stakeContract.getAddress(), stakeAmount);
            await stakeContract.connect(user1).stake(0, stakeAmount);

            // Emergency withdraw
            const balanceBefore = await testToken.balanceOf(user1.address);
            await stakeContract.connect(user1).emergencyWithdraw(0);
            const balanceAfter = await testToken.balanceOf(user1.address);

            expect(balanceAfter - balanceBefore).to.equal(stakeAmount);

            // User data should be reset
            const user = await stakeContract.getUser(0, user1.address);
            expect(user.stAmount).to.equal(0);
            expect(user.pendingMetaNode).to.equal(0);
        });

        it("Should allow admin to pause/unpause", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            // Add pool
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            // Pause contract
            await stakeContract.connect(owner).pause();

            // Staking should fail when paused
            await testToken.connect(user1).approve(await stakeContract.getAddress(), ethers.parseEther("10"));
            await expect(
                stakeContract.connect(user1).stake(0, ethers.parseEther("10"))
            ).to.be.revertedWithCustomError(stakeContract, "EnforcedPause");

            // Unpause
            await stakeContract.connect(owner).unpause();

            // Staking should work again
            await expect(
                stakeContract.connect(user1).stake(0, ethers.parseEther("10"))
            ).to.emit(stakeContract, "Staked");
        });
    });

    describe("Access Control", function () {
        it("Should enforce admin role for sensitive functions", async function () {
            const { stakeContract, testToken, user1 } = await loadFixture(deployContractsFixture);

            await expect(
                stakeContract.connect(user1).addPool(
                    await testToken.getAddress(),
                    100,
                    ethers.parseEther("1"),
                    100
                )
            ).to.be.revertedWith("MetaNodeStake: Caller is not admin");

            await expect(
                stakeContract.connect(user1).setRewardPerBlock(ethers.parseEther("2"))
            ).to.be.revertedWith("MetaNodeStake: Caller is not admin");

            await expect(
                stakeContract.connect(user1).pause()
            ).to.be.revertedWith("MetaNodeStake: Caller is not admin");
        });
    });

    describe("Edge Cases", function () {
        it("Should handle zero staking amount", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"), // Set minimum stake amount
                100
            );

            await expect(
                stakeContract.connect(user1).stake(0, 0)
            ).to.be.revertedWith("MetaNodeStake: Amount below minimum");
        });

        it("Should handle invalid pool ID", async function () {
            const { stakeContract, user1 } = await loadFixture(deployContractsFixture);

            await expect(
                stakeContract.connect(user1).stake(999, ethers.parseEther("1"))
            ).to.be.revertedWith("MetaNodeStake: Invalid pool ID");
        });

        it("Should handle insufficient staked amount for unstaking", async function () {
            const { stakeContract, testToken, owner, user1 } = await loadFixture(deployContractsFixture);

            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            await expect(
                stakeContract.connect(user1).unstake(0, ethers.parseEther("1"))
            ).to.be.revertedWith("MetaNodeStake: Insufficient staked amount");
        });
    });

    describe("UUPS Upgrade", function () {
        it("Should upgrade contract successfully", async function () {
            const { stakeContract, metaNodeToken, owner, rewardPerBlock } = await loadFixture(deployContractsFixture);

            // Get the current implementation address
            const currentImplementation = await upgrades.erc1967.getImplementationAddress(await stakeContract.getAddress());

            // Deploy a new version of the contract (for testing, we'll use the same contract)
            const MetaNodeStakeV2 = await ethers.getContractFactory("MetaNodeStake");
            
            // Upgrade the contract
            const upgradedContract = await upgrades.upgradeProxy(await stakeContract.getAddress(), MetaNodeStakeV2, {
                unsafeAllow: ['constructor']
            });

            // Verify that the proxy address remains the same
            expect(await upgradedContract.getAddress()).to.equal(await stakeContract.getAddress());

            // Verify that the state is preserved
            expect(await upgradedContract.metaNodeToken()).to.equal(await metaNodeToken.getAddress());
            expect(await upgradedContract.rewardPerBlock()).to.equal(rewardPerBlock);
            expect(await upgradedContract.hasRole(await upgradedContract.ADMIN_ROLE(), owner.address)).to.be.true;

            // Verify that the contract is still functional
            expect(await upgradedContract.poolLength()).to.equal(0);
        });

        it("Should only allow admin to authorize upgrade", async function () {
            const { stakeContract, user1 } = await loadFixture(deployContractsFixture);

            const MetaNodeStakeV2 = await ethers.getContractFactory("MetaNodeStake");

            // Try to upgrade with non-admin account - should fail
            await expect(
                upgrades.upgradeProxy(await stakeContract.getAddress(), MetaNodeStakeV2.connect(user1), {
                    unsafeAllow: ['constructor']
                })
            ).to.be.revertedWith("MetaNodeStake: Caller is not admin");
        });

        it("Should preserve state after upgrade", async function () {
            const { stakeContract, testToken, metaNodeToken, owner, user1 } = await loadFixture(deployContractsFixture);

            // Add a pool and stake some tokens before upgrade
            await stakeContract.connect(owner).addPool(
                await testToken.getAddress(),
                100,
                ethers.parseEther("1"),
                100
            );

            await testToken.connect(user1).approve(await stakeContract.getAddress(), ethers.parseEther("10"));
            await stakeContract.connect(user1).stake(0, ethers.parseEther("10"));

            // Store state before upgrade
            const poolBefore = await stakeContract.getPool(0);
            const userBefore = await stakeContract.getUser(0, user1.address);
            const poolLengthBefore = await stakeContract.poolLength();

            // Upgrade the contract
            const MetaNodeStakeV2 = await ethers.getContractFactory("MetaNodeStake");
            const upgradedContract = await upgrades.upgradeProxy(await stakeContract.getAddress(), MetaNodeStakeV2, {
                unsafeAllow: ['constructor']
            });

            // Verify state is preserved
            const poolAfter = await upgradedContract.getPool(0);
            const userAfter = await upgradedContract.getUser(0, user1.address);
            const poolLengthAfter = await upgradedContract.poolLength();

            expect(poolAfter.stTokenAddress).to.equal(poolBefore.stTokenAddress);
            expect(poolAfter.poolWeight).to.equal(poolBefore.poolWeight);
            expect(poolAfter.stTokenAmount).to.equal(poolBefore.stTokenAmount);
            expect(userAfter.stAmount).to.equal(userBefore.stAmount);
            expect(poolLengthAfter).to.equal(poolLengthBefore);

            // Verify functionality still works after upgrade
            await stakeContract.connect(user1).unstake(0, ethers.parseEther("5"));
            const userAfterUnstake = await upgradedContract.getUser(0, user1.address);
            expect(userAfterUnstake.stAmount).to.equal(ethers.parseEther("5"));
        });
    });
});