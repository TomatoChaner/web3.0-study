const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenVesting", function () {
    let token;
    let vesting;
    let owner;
    let beneficiary;
    let user1;

    beforeEach(async function () {
        [owner, beneficiary, user1] = await ethers.getSigners();

        // 部署模拟工厂合约
        const MockFactory = await ethers.getContractFactory("MockFactory");
        const mockFactory = await MockFactory.deploy();

        // 部署模拟路由器合约
        const MockRouter = await ethers.getContractFactory("MockRouter");
        const mockRouter = await MockRouter.deploy(mockFactory.address, user1.address);

        // 部署一个简单的ERC20代币用于测试
        const Token = await ethers.getContractFactory("ShibMemeToken");
        token = await Token.deploy(
            owner.address,
            owner.address,
            owner.address,
            mockRouter.address
        );

        // 部署TokenVesting合约
        const TokenVesting = await ethers.getContractFactory("TokenVesting");
        vesting = await TokenVesting.deploy(token.address);

        // 启用交易以允许代币转账
        await token.enableTrading();
    });

    describe("创建归属计划", function () {
        it("应该允许创建新的归属计划", async function () {
            const amount = ethers.utils.parseEther("1000");
            const start = Math.floor(Date.now() / 1000);
            const cliff = 30 * 24 * 60 * 60; // 30天
            const duration = 365 * 24 * 60 * 60; // 1年

            // 先给vesting合约转账代币
            await token.transfer(vesting.address, amount);

            await expect(vesting.createVestingSchedule(
                beneficiary.address,
                start,
                cliff,
                duration,
                1,
                true,
                amount
            )).to.emit(vesting, "VestingScheduleCreated");
        });

        it("应该拒绝零地址受益人", async function () {
            const amount = ethers.utils.parseEther("1000");
            const start = Math.floor(Date.now() / 1000);
            const cliff = 30 * 24 * 60 * 60;
            const duration = 365 * 24 * 60 * 60;

            await expect(vesting.createVestingSchedule(
                ethers.constants.AddressZero,
                start,
                cliff,
                duration,
                1,
                true,
                amount
            )).to.be.revertedWith("TokenVesting: beneficiary is zero address");
        });

        it("应该拒绝零数量", async function () {
            const start = Math.floor(Date.now() / 1000);
            const cliff = 30 * 24 * 60 * 60;
            const duration = 365 * 24 * 60 * 60;

            await expect(vesting.createVestingSchedule(
                beneficiary.address,
                start,
                cliff,
                duration,
                1,
                true,
                0
            )).to.be.revertedWith("TokenVesting: amount must be > 0");
        });
    });

    describe("代币释放", function () {
        let vestingScheduleId;
        const amount = ethers.utils.parseEther("1000");

        beforeEach(async function () {
            // 获取当前区块时间戳
            const currentBlock = await ethers.provider.getBlock("latest");
            const start = currentBlock.timestamp;
            const cliff = 30 * 24 * 60 * 60; // 30天
            const duration = 365 * 24 * 60 * 60; // 365天

            await token.transfer(vesting.address, amount);

            await vesting.createVestingSchedule(
                beneficiary.address,
                start,
                cliff,
                duration,
                1,
                true,
                amount
            );

            vestingScheduleId = await vesting.computeVestingScheduleIdForAddressAndIndex(
                beneficiary.address,
                0
            );
        });

        it("应该允许受益人释放已解锁的代币", async function () {
            // 快进时间到cliff之后
            await ethers.provider.send("evm_increaseTime", [31 * 24 * 60 * 60]);
            await ethers.provider.send("evm_mine");

            const releasableAmount = await vesting.computeReleasableAmount(vestingScheduleId);
            expect(releasableAmount).to.be.gt(0);

            await expect(vesting.connect(beneficiary).release(vestingScheduleId, releasableAmount))
                .to.emit(vesting, "TokensReleased");
        });

        it("应该正确计算可释放数量", async function () {
            // 在cliff期间，应该没有可释放的代币
            const releasableBeforeCliff = await vesting.computeReleasableAmount(vestingScheduleId);
            expect(releasableBeforeCliff).to.equal(0);

            // 快进到cliff之后
            await ethers.provider.send("evm_increaseTime", [31 * 24 * 60 * 60]);
            await ethers.provider.send("evm_mine");

            const releasableAfterCliff = await vesting.computeReleasableAmount(vestingScheduleId);
            expect(releasableAfterCliff).to.be.gt(0);
        });
    });

    describe("撤销归属", function () {
        let vestingScheduleId;
        const amount = ethers.utils.parseEther("1000");

        beforeEach(async function () {
            // 获取当前区块时间戳
            const currentBlock = await ethers.provider.getBlock("latest");
            const start = currentBlock.timestamp;
            const cliff = 30 * 24 * 60 * 60; // 30天
            const duration = 365 * 24 * 60 * 60; // 365天

            await token.transfer(vesting.address, amount);

            await vesting.createVestingSchedule(
                beneficiary.address,
                start,
                cliff,
                duration,
                1,
                true, // 可撤销
                amount
            );

            vestingScheduleId = await vesting.computeVestingScheduleIdForAddressAndIndex(
                beneficiary.address,
                0
            );
        });

        it("应该允许所有者撤销可撤销的归属计划", async function () {
            await expect(vesting.revoke(vestingScheduleId))
                .to.emit(vesting, "VestingScheduleRevoked");
        });

        it("应该拒绝撤销不可撤销的归属计划", async function () {
            // 创建一个不可撤销的归属计划
            const start = Math.floor(Date.now() / 1000);
            const cliff = 30 * 24 * 60 * 60;
            const duration = 365 * 24 * 60 * 60;

            await token.transfer(vesting.address, amount);

            await vesting.createVestingSchedule(
                user1.address,
                start,
                cliff,
                duration,
                1,
                false, // 不可撤销
                amount
            );

            const nonRevocableId = await vesting.computeVestingScheduleIdForAddressAndIndex(
                user1.address,
                0
            );

            await expect(vesting.revoke(nonRevocableId))
                .to.be.revertedWith("TokenVesting: vesting schedule not revocable");
        });
    });

    describe("查询功能", function () {
        it("应该正确返回归属计划数量", async function () {
            expect(await vesting.getVestingSchedulesTotalCount()).to.equal(0);

            const amount = ethers.utils.parseEther("1000");
            const start = Math.floor(Date.now() / 1000);
            const cliff = 30 * 24 * 60 * 60;
            const duration = 365 * 24 * 60 * 60;

            await token.transfer(vesting.address, amount);

            await vesting.createVestingSchedule(
                beneficiary.address,
                start,
                cliff,
                duration,
                1,
                true,
                amount
            );

            expect(await vesting.getVestingSchedulesTotalCount()).to.equal(1);
        });

        it("应该正确返回受益人的归属计划数量", async function () {
            expect(await vesting.getVestingSchedulesCountByBeneficiary(beneficiary.address)).to.equal(0);

            const amount = ethers.utils.parseEther("1000");
            const start = Math.floor(Date.now() / 1000);
            const cliff = 30 * 24 * 60 * 60;
            const duration = 365 * 24 * 60 * 60;

            await token.transfer(vesting.address, amount);

            await vesting.createVestingSchedule(
                beneficiary.address,
                start,
                cliff,
                duration,
                1,
                true,
                amount
            );

            expect(await vesting.getVestingSchedulesCountByBeneficiary(beneficiary.address)).to.equal(1);
        });
    });

    describe("紧急提取功能", function () {
        it("应该允许所有者紧急提取非归属代币", async function () {
            // 部署一个测试代币
            const TestToken = await ethers.getContractFactory("TestToken");
            const testToken = await TestToken.deploy("Test Token", "TEST", ethers.utils.parseEther("10000"));
            
            const amount = ethers.utils.parseEther("1000");
            await testToken.transfer(vesting.address, amount);

            // 应该能够提取测试代币
            await expect(vesting.emergencyWithdraw(testToken.address, amount))
                .to.not.be.reverted;
        });

        it("应该拒绝提取归属代币", async function () {
            const amount = ethers.utils.parseEther("1000");
            await token.transfer(vesting.address, amount);

            await expect(vesting.emergencyWithdraw(token.address, amount))
                .to.be.revertedWith("TokenVesting: cannot withdraw vesting token");
        });
    });
});