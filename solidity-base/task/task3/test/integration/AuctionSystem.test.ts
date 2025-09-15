import { expect } from "chai";
import { ethers } from "hardhat";
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { AuctionFactory, AuctionHouse, AuctionNFT, PriceOracle } from "../../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("AuctionSystem Integration", function () {
    // 测试常量
    const PLATFORM_FEE_RATE = 250; // 2.5%
    const CREATION_FEE = ethers.parseEther("0.001");
    const STARTING_PRICE = ethers.parseEther("1");
    const RESERVE_PRICE = ethers.parseEther("2");
    const AUCTION_DURATION = 24 * 60 * 60; // 24小时
    const TOKEN_ID = 0;

    // 测试账户
    let owner: SignerWithAddress;
    let feeRecipient: SignerWithAddress;
    let seller: SignerWithAddress;
    let bidder1: SignerWithAddress;
    let bidder2: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    // 合约实例
    let auctionFactory: AuctionFactory;
    let auctionNFT: AuctionNFT;
    let auctionHouse1: AuctionHouse;
    let auctionHouse2: AuctionHouse;
    let mockPriceOracle: PriceOracle;

    /**
     * @dev 部署测试环境
     */
    async function deployAuctionSystemFixture() {
        // 获取测试账户
        [owner, feeRecipient, seller, bidder1, bidder2, user1, user2] = await ethers.getSigners();

        // 部署价格预言机
        const MockPriceOracleFactory = await ethers.getContractFactory("PriceOracle");
        mockPriceOracle = await MockPriceOracleFactory.deploy();

        // 部署NFT合约
        const AuctionNFTFactory = await ethers.getContractFactory("AuctionNFT");
        auctionNFT = await AuctionNFTFactory.deploy("Test NFT", "TNFT");

        // 部署工厂合约
        const AuctionFactoryContract = await ethers.getContractFactory("AuctionFactory");
        auctionFactory = await AuctionFactoryContract.deploy(
            feeRecipient.address,
            await mockPriceOracle.getAddress()
        );

        // 设置NFT合约为支持的合约
        await auctionFactory.setNFTSupport(await auctionNFT.getAddress(), true);

        // 为测试用户铸造NFT
        await auctionNFT.mint(seller.address, "ipfs://test-metadata-1");
        await auctionNFT.mint(user1.address, "ipfs://test-metadata-2");
        await auctionNFT.mint(user2.address, "ipfs://test-metadata-3");

        return {
            auctionFactory,
            auctionNFT,
            mockPriceOracle,
            owner,
            feeRecipient,
            seller,
            bidder1,
            bidder2,
            user1,
            user2
        };
    }

    beforeEach(async function () {
        const fixture = await loadFixture(deployAuctionSystemFixture);
        auctionFactory = fixture.auctionFactory;
        auctionNFT = fixture.auctionNFT;
        mockPriceOracle = fixture.mockPriceOracle;
        owner = fixture.owner;
        feeRecipient = fixture.feeRecipient;
        seller = fixture.seller;
        bidder1 = fixture.bidder1;
        bidder2 = fixture.bidder2;
        user1 = fixture.user1;
        user2 = fixture.user2;
    });

    describe("工厂合约部署和配置", function () {
        it("应该正确部署工厂合约", async function () {
            expect(await auctionFactory.owner()).to.equal(owner.address);
            
            const config = await auctionFactory.globalConfig();
            expect(config.platformFeeRate).to.equal(PLATFORM_FEE_RATE);
            expect(config.feeRecipient).to.equal(feeRecipient.address);
            expect(config.creationFee).to.equal(CREATION_FEE);
        });

        it("应该正确设置NFT合约支持状态", async function () {
            expect(await auctionFactory.supportedNFTs(await auctionNFT.getAddress())).to.be.true;
            
            // 测试取消支持
            await auctionFactory.setNFTSupport(await auctionNFT.getAddress(), false);
            expect(await auctionFactory.supportedNFTs(await auctionNFT.getAddress())).to.be.false;
            
            // 恢复支持
            await auctionFactory.setNFTSupport(await auctionNFT.getAddress(), true);
        });

        it("应该有默认模板", async function () {
            expect(await auctionFactory.getTotalTemplates()).to.equal(1);
            
            const template = await auctionFactory.getTemplate(0);
            expect(template.active).to.be.true;
            expect(template.version).to.equal("1.0.0");
            
            const activeTemplates = await auctionFactory.getActiveTemplates();
            expect(activeTemplates.length).to.equal(1);
            expect(activeTemplates[0]).to.equal(0);
        });
    });

    describe("拍卖行实例创建", function () {
        it("应该成功创建拍卖行实例", async function () {
            const tx = await auctionFactory.connect(seller).createAuctionHouse(
                await auctionNFT.getAddress(),
                "Test Auction House",
                0, // 使用默认模板
                "0x" // 空的初始化数据
            );
            
            await expect(tx)
                .to.emit(auctionFactory, "AuctionHouseCreated");
            
            // 验证拍卖行实例已创建
            const userAuctionHouses = await auctionFactory.getAuctionHousesByOwner(seller.address);
            expect(userAuctionHouses.length).to.equal(1);
            
            const auctionHouseAddress = userAuctionHouses[0];
            expect(await auctionFactory.isValidAuctionHouse(auctionHouseAddress)).to.be.true;
        });

        it("应该拒绝不支持的NFT合约", async function () {
            // 部署一个未支持的NFT合约
            const AuctionNFTFactory = await ethers.getContractFactory("AuctionNFT");
            const unsupportedNFT = await AuctionNFTFactory.deploy("Unsupported NFT", "UNFT");
            
            await expect(
                auctionFactory.connect(seller).createAuctionHouse(
                    await unsupportedNFT.getAddress(),
                    "Test Auction House",
                    0,
                    "0x"
                )
            ).to.be.revertedWith("NFT contract not supported");
        });

        it("应该拒绝无效的模板ID", async function () {
            await expect(
                auctionFactory.connect(seller).createAuctionHouse(
                    await auctionNFT.getAddress(),
                    "Test Auction House",
                    999, // 无效的模板ID
                    "0x"
                )
            ).to.be.revertedWith("Invalid template ID");
        });

        it("应该正确管理NFT对应的拍卖行", async function () {
            await auctionFactory.connect(seller).createAuctionHouse(
                await auctionNFT.getAddress(),
                "Test Auction House 1",
                0,
                "0x"
            );
            
            await auctionFactory.connect(user1).createAuctionHouse(
                await auctionNFT.getAddress(),
                "Test Auction House 2",
                0,
                "0x"
            );
            
            const nftAuctionHouses = await auctionFactory.getAuctionHousesByNFT(await auctionNFT.getAddress());
            expect(nftAuctionHouses.length).to.equal(2);
        });
    });

    describe("多拍卖行实例管理", function () {
        beforeEach(async function () {
            // 创建多个拍卖行实例
            await auctionFactory.connect(seller).createAuctionHouse(
                await auctionNFT.getAddress(),
                "Seller Auction House",
                0,
                "0x"
            );
            
            await auctionFactory.connect(user1).createAuctionHouse(
                await auctionNFT.getAddress(),
                "User1 Auction House",
                0,
                "0x"
            );
            
            await auctionFactory.connect(user2).createAuctionHouse(
                await auctionNFT.getAddress(),
                "User2 Auction House",
                0,
                "0x"
            );
            
            // 获取拍卖行合约实例
            const sellerAuctionHouses = await auctionFactory.getAuctionHousesByOwner(seller.address);
            const user1AuctionHouses = await auctionFactory.getAuctionHousesByOwner(user1.address);
            
            auctionHouse1 = await ethers.getContractAt("AuctionHouse", sellerAuctionHouses[0]);
            auctionHouse2 = await ethers.getContractAt("AuctionHouse", user1AuctionHouses[0]);
        });

        it("应该正确管理多个拍卖行实例", async function () {
            expect(await auctionFactory.getTotalAuctionHouses()).to.equal(3);
            
            // 验证每个用户的拍卖行列表
            expect((await auctionFactory.getAuctionHousesByOwner(seller.address)).length).to.equal(1);
            expect((await auctionFactory.getAuctionHousesByOwner(user1.address)).length).to.equal(1);
            expect((await auctionFactory.getAuctionHousesByOwner(user2.address)).length).to.equal(1);
        });

        it("应该支持独立的拍卖操作", async function () {
            // 授权NFT给拍卖行合约
            await auctionNFT.connect(seller).approve(await auctionHouse1.getAddress(), TOKEN_ID);
            await auctionNFT.connect(user1).approve(await auctionHouse2.getAddress(), 1);
            
            // 在不同拍卖行实例中创建拍卖
            await auctionHouse1.connect(seller).createAuction(
                await auctionNFT.getAddress(),
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                ethers.parseEther("0.1") // bidIncrement
            );
            
            await auctionHouse2.connect(user1).createAuction(
                await auctionNFT.getAddress(),
                1,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                ethers.parseEther("0.1") // bidIncrement
            );
            
            // 验证拍卖独立运行
            const auction1Info = await auctionHouse1.getAuction(0);
            const auction2Info = await auctionHouse2.getAuction(0);
            
            expect(auction1Info.seller).to.equal(seller.address);
            expect(auction2Info.seller).to.equal(user1.address);
            expect(auction1Info.tokenId).to.equal(TOKEN_ID);
            expect(auction2Info.tokenId).to.equal(1);
        });

        it("应该支持并发出价操作", async function () {
            // 设置拍卖
            await auctionNFT.connect(seller).approve(await auctionHouse1.getAddress(), TOKEN_ID);
            await auctionNFT.connect(user1).approve(await auctionHouse2.getAddress(), 1);
            
            await auctionHouse1.connect(seller).createAuction(
                await auctionNFT.getAddress(),
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                ethers.parseEther("0.1") // bidIncrement
            );
            
            await auctionHouse2.connect(user1).createAuction(
                await auctionNFT.getAddress(),
                1,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                ethers.parseEther("0.1") // bidIncrement
            );
            
            // 并发出价
            await auctionHouse1.connect(bidder1).placeBid(0, { value: STARTING_PRICE });
            await auctionHouse2.connect(bidder2).placeBid(0, { value: STARTING_PRICE });
            
            // 验证出价记录
            const auction1Info = await auctionHouse1.getAuction(0);
            const auction2Info = await auctionHouse2.getAuction(0);
            
            expect(auction1Info.currentBidder).to.equal(bidder1.address);
            expect(auction2Info.currentBidder).to.equal(bidder2.address);
        });
    });

    describe("模板管理", function () {
        it("应该允许所有者添加新模板", async function () {
            // 部署新的AuctionHouse作为模板
            const AuctionHouseFactory = await ethers.getContractFactory("AuctionHouse");
            const newTemplate = await AuctionHouseFactory.deploy(
                feeRecipient.address,
                await mockPriceOracle.getAddress()
            );
            
            await expect(
                auctionFactory.addTemplate(await newTemplate.getAddress(), "2.0.0")
            ).to.emit(auctionFactory, "TemplateAdded")
            .withArgs(1, await newTemplate.getAddress(), "2.0.0");
            
            expect(await auctionFactory.getTotalTemplates()).to.equal(2);
            
            const template = await auctionFactory.getTemplate(1);
            expect(template.implementation).to.equal(await newTemplate.getAddress());
            expect(template.version).to.equal("2.0.0");
            expect(template.active).to.be.true;
        });

        it("应该允许所有者更新模板", async function () {
            const AuctionHouseFactory = await ethers.getContractFactory("AuctionHouse");
            const updatedTemplate = await AuctionHouseFactory.deploy(
                feeRecipient.address,
                await mockPriceOracle.getAddress()
            );
            
            await expect(
                auctionFactory.updateTemplate(0, await updatedTemplate.getAddress(), "1.1.0")
            ).to.emit(auctionFactory, "TemplateUpdated")
            .withArgs(0, await updatedTemplate.getAddress(), "1.1.0");
            
            const template = await auctionFactory.getTemplate(0);
            expect(template.implementation).to.equal(await updatedTemplate.getAddress());
            expect(template.version).to.equal("1.1.0");
        });

        it("应该允许所有者停用模板", async function () {
            await expect(
                auctionFactory.deactivateTemplate(0)
            ).to.emit(auctionFactory, "TemplateDeactivated")
            .withArgs(0);
            
            const template = await auctionFactory.getTemplate(0);
            expect(template.active).to.be.false;
            
            const activeTemplates = await auctionFactory.getActiveTemplates();
            expect(activeTemplates.length).to.equal(0);
        });
    });

    describe("工厂配置管理", function () {
        it("应该允许所有者更新全局配置", async function () {
            const newFeeRate = 300; // 3%
            const newFeeRecipient = user1.address;
            const newCreationFee = ethers.parseEther("0.002");
            
            await expect(
                auctionFactory.updateGlobalConfig(
                    newFeeRate,
                    newFeeRecipient,
                    await mockPriceOracle.getAddress(),
                    newCreationFee
                )
            ).to.emit(auctionFactory, "GlobalConfigUpdated")
            .withArgs(newFeeRate, newFeeRecipient, newCreationFee);
            
            const config = await auctionFactory.globalConfig();
            expect(config.platformFeeRate).to.equal(newFeeRate);
            expect(config.feeRecipient).to.equal(newFeeRecipient);
            expect(config.creationFee).to.equal(newCreationFee);
        });

        it("应该拒绝非所有者更新配置", async function () {
            await expect(
                auctionFactory.connect(seller).updateGlobalConfig(
                    300,
                    user1.address,
                    await mockPriceOracle.getAddress(),
                    ethers.parseEther("0.002")
                )
            ).to.be.revertedWithCustomError(auctionFactory, "OwnableUnauthorizedAccount");
        });

        it("应该拒绝无效的配置参数", async function () {
            // 手续费率过高
            await expect(
                auctionFactory.updateGlobalConfig(
                    1001, // 超过10%
                    feeRecipient.address,
                    await mockPriceOracle.getAddress(),
                    CREATION_FEE
                )
            ).to.be.revertedWith("Fee rate too high");
            
            // 无效的手续费接收地址
            await expect(
                auctionFactory.updateGlobalConfig(
                    PLATFORM_FEE_RATE,
                    ethers.ZeroAddress,
                    await mockPriceOracle.getAddress(),
                    CREATION_FEE
                )
            ).to.be.revertedWith("Invalid fee recipient");
        });
    });

    describe("暂停和恢复功能", function () {
        it("应该允许所有者暂停和恢复合约", async function () {
            // 暂停合约
            await auctionFactory.pause();
            expect(await auctionFactory.paused()).to.be.true;
            
            // 暂停状态下无法创建拍卖行
            await expect(
                auctionFactory.connect(seller).createAuctionHouse(
                    await auctionNFT.getAddress(),
                    "Test Auction House",
                    0,
                    "0x"
                )
            ).to.be.revertedWithCustomError(auctionFactory, "EnforcedPause");
            
            // 恢复合约
            await auctionFactory.unpause();
            expect(await auctionFactory.paused()).to.be.false;
            
            // 恢复后可以正常创建拍卖行
            await expect(
                auctionFactory.connect(seller).createAuctionHouse(
                    await auctionNFT.getAddress(),
                    "Test Auction House",
                    0,
                    "0x"
                )
            ).to.not.be.reverted;
        });
    });
});