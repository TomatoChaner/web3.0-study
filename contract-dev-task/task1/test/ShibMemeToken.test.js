const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ShibMemeToken", function () {
    let token;
    let owner;
    let marketingWallet;
    let developmentWallet;
    let liquidityWallet;
    let user1;
    let user2;

    beforeEach(async function () {
        [owner, marketingWallet, developmentWallet, liquidityWallet, user1, user2] = await ethers.getSigners();

        // 部署模拟工厂合约
        const MockFactory = await ethers.getContractFactory("MockFactory");
        const mockFactory = await MockFactory.deploy();
        await mockFactory.deployed();

        // 部署模拟路由器合约
        const MockRouter = await ethers.getContractFactory("MockRouter");
        const mockRouter = await MockRouter.deploy(mockFactory.address, user1.address); // 使用user1作为WETH地址
        await mockRouter.deployed();

        // 部署ShibMemeToken合约
        const ShibMemeToken = await ethers.getContractFactory("ShibMemeToken");
        token = await ShibMemeToken.deploy(
            marketingWallet.address,
            developmentWallet.address,
            liquidityWallet.address,
            mockRouter.address
        );
        await token.deployed();
    });

    describe("部署", function () {
        it("应该正确设置代币名称和符号", async function () {
            expect(await token.name()).to.equal("SHIB Meme Token");
            expect(await token.symbol()).to.equal("SMT");
        });

        it("应该正确设置小数位数", async function () {
            expect(await token.decimals()).to.equal(18);
        });

        it("应该正确设置总供应量", async function () {
            const totalSupply = await token.totalSupply();
            expect(totalSupply).to.equal(ethers.utils.parseEther("1000000000")); // 10亿代币
        });

        it("应该将所有代币分配给所有者", async function () {
            const ownerBalance = await token.balanceOf(owner.address);
            const totalSupply = await token.totalSupply();
            expect(ownerBalance).to.equal(totalSupply);
        });

        it("应该正确设置钱包地址", async function () {
            expect(await token.marketingWallet()).to.equal(marketingWallet.address);
            expect(await token.developmentWallet()).to.equal(developmentWallet.address);
            expect(await token.liquidityWallet()).to.equal(liquidityWallet.address);
        });
    });

    describe("税收管理", function () {
        it("应该允许所有者设置买入税", async function () {
            await token.setBuyTax(300); // 3%
            expect(await token.buyTax()).to.equal(300);
        });

        it("应该允许所有者设置卖出税", async function () {
            await token.setSellTax(500); // 5%
            expect(await token.sellTax()).to.equal(500);
        });

        it("应该拒绝设置过高的税率", async function () {
            await expect(token.setBuyTax(1001)).to.be.revertedWith("ShibMemeToken: buy tax too high");
            await expect(token.setSellTax(1001)).to.be.revertedWith("ShibMemeToken: sell tax too high");
        });

        it("应该拒绝非所有者设置税率", async function () {
            await expect(token.connect(user1).setBuyTax(300)).to.be.reverted;
            await expect(token.connect(user1).setSellTax(500)).to.be.reverted;
        });
    });

    describe("交易限制", function () {
        it("应该允许所有者更新限制", async function () {
            const newMaxTx = ethers.utils.parseEther("1000000"); // 100万代币
            const newMaxWallet = ethers.utils.parseEther("2000000"); // 200万代币

            await token.setMaxTransactionAmount(newMaxTx);
            await token.setMaxWalletAmount(newMaxWallet);

            expect(await token.maxTransactionAmount()).to.equal(newMaxTx);
            expect(await token.maxWalletAmount()).to.equal(newMaxWallet);
        });

        it("应该拒绝设置过低的限制", async function () {
            const tooLowAmount = ethers.utils.parseEther("1000"); // 1000代币，低于0.1%
            
            await expect(token.setMaxTransactionAmount(tooLowAmount))
                .to.be.revertedWith("ShibMemeToken: max transaction amount too low");
                
            await expect(token.setMaxWalletAmount(tooLowAmount))
                .to.be.revertedWith("ShibMemeToken: max wallet amount too low");
        });
    });

    describe("黑名单管理", function () {
        it("应该允许所有者添加和移除黑名单", async function () {
            // 添加到黑名单
            await token.setBlacklisted(user1.address, true);
            expect(await token.isBlacklisted(user1.address)).to.be.true;

            // 从黑名单移除
            await token.setBlacklisted(user1.address, false);
            expect(await token.isBlacklisted(user1.address)).to.be.false;
        });

        it("应该阻止黑名单用户转账", async function () {
            // 先给user1一些代币
            await token.transfer(user1.address, ethers.utils.parseEther("1000"));

            // 将user1添加到黑名单
            await token.setBlacklisted(user1.address, true);

            // user1应该无法转账
            await expect(token.connect(user1).transfer(user2.address, ethers.utils.parseEther("100")))
                .to.be.revertedWith("ShibMemeToken: sender is blacklisted");
        });
    });

    describe("费用排除", function () {
        it("应该允许所有者设置费用排除", async function () {
            await token.setExcludedFromFees(user1.address, true);
            expect(await token.isExcludedFromFees(user1.address)).to.be.true;

            await token.setExcludedFromFees(user1.address, false);
            expect(await token.isExcludedFromFees(user1.address)).to.be.false;
        });
    });

    describe("基本转账功能", function () {
        it("应该允许基本转账", async function () {
            const transferAmount = ethers.utils.parseEther("1000");
            
            await token.transfer(user1.address, transferAmount);
            
            expect(await token.balanceOf(user1.address)).to.equal(transferAmount);
        });

        it("应该允许授权转账", async function () {
            const transferAmount = ethers.utils.parseEther("1000");
            
            // 所有者授权user1花费代币
            await token.approve(user1.address, transferAmount);
            expect(await token.allowance(owner.address, user1.address)).to.equal(transferAmount);
            
            // user1代表所有者转账给user2
            await token.connect(user1).transferFrom(owner.address, user2.address, transferAmount);
            
            expect(await token.balanceOf(user2.address)).to.equal(transferAmount);
        });
    });

    describe("暂停功能", function () {
        it("应该允许所有者暂停和恢复合约", async function () {
            // 暂停合约
            await token.pause();
            expect(await token.paused()).to.be.true;

            // 暂停时应该无法转账
            await expect(token.transfer(user1.address, ethers.utils.parseEther("100")))
                .to.be.revertedWith("ShibMemeToken: token transfer while paused");

            // 恢复合约
            await token.unpause();
            expect(await token.paused()).to.be.false;

            // 恢复后应该可以转账
            await token.transfer(user1.address, ethers.utils.parseEther("100"));
            expect(await token.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("100"));
        });
    });

    describe("紧急功能", function () {
        it("应该允许所有者提取ETH", async function () {
            // 向合约发送一些ETH
            await owner.sendTransaction({
                to: token.address,
                value: ethers.utils.parseEther("1")
            });

            const initialBalance = await owner.getBalance();
            
            // 提取ETH
            const tx = await token.emergencyWithdrawETH();
            const receipt = await tx.wait();
            const gasUsed = receipt.gasUsed.mul(receipt.effectiveGasPrice);
            
            const finalBalance = await owner.getBalance();
            
            // 检查余额增加（减去gas费用）
            expect(finalBalance.add(gasUsed).sub(initialBalance)).to.equal(ethers.utils.parseEther("1"));
        });
    });
});