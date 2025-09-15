import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
    AuctionHouseUpgradeable,
    AuctionNFT,
    CrossChainMessenger,
    CrossChainNetworkManager,
    CrossChainBidSettlement
} from "../../typechain-types";

describe("CrossChainAuction Integration Tests", function () {
    let owner: SignerWithAddress;
    let bidder1: SignerWithAddress;
    let bidder2: SignerWithAddress;
    let auctionHouse: AuctionHouseUpgradeable;
    let nftContract: AuctionNFT;
    let crossChainMessenger: CrossChainMessenger;
    let networkManager: CrossChainNetworkManager;
    let bidSettlement: CrossChainBidSettlement;
    let mockRouter: any;
    let mockLinkToken: any;
    let mockPriceOracle: any;

    beforeEach(async function () {
        [owner, bidder1, bidder2] = await ethers.getSigners();

        // 部署模拟合约
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        mockLinkToken = await MockERC20.deploy("LINK", "LINK", 18);
        await mockLinkToken.waitForDeployment();

        // 部署模拟路由器
        const MockRouter = await ethers.getContractFactory("MockCCIPRouter");
        mockRouter = await MockRouter.deploy();
        await mockRouter.waitForDeployment();

        // 部署模拟价格预言机
        const MockPriceOracle = await ethers.getContractFactory("MockPriceOracle");
        mockPriceOracle = await MockPriceOracle.deploy();
        await mockPriceOracle.waitForDeployment();

        // 部署NFT合约
        const NFTFactory = await ethers.getContractFactory("AuctionNFT");
        nftContract = await NFTFactory.deploy("AuctionNFT", "ANFT");
        await nftContract.waitForDeployment();

        // 部署拍卖合约
        const AuctionFactory = await ethers.getContractFactory("AuctionHouseUpgradeable");
        auctionHouse = await AuctionFactory.deploy();
        await auctionHouse.waitForDeployment();
        await auctionHouse.initialize(
            owner.address,
            await mockPriceOracle.getAddress()
        );

        // 部署跨链网络管理器
        const NetworkManagerFactory = await ethers.getContractFactory("CrossChainNetworkManager");
        networkManager = await NetworkManagerFactory.deploy(
            owner.address,
            await mockPriceOracle.getAddress()
        );
        await networkManager.waitForDeployment();

        // 部署跨链消息传递器
        const MessengerFactory = await ethers.getContractFactory("CrossChainMessenger");
        crossChainMessenger = await MessengerFactory.deploy(
            await mockRouter.getAddress(),
            await mockLinkToken.getAddress(),
            owner.address
        );
        await crossChainMessenger.waitForDeployment();

        // 部署跨链出价结算合约
        const SettlementFactory = await ethers.getContractFactory("CrossChainBidSettlement");
        bidSettlement = await SettlementFactory.deploy(
            await crossChainMessenger.getAddress(),
            await mockPriceOracle.getAddress()
        );
        await bidSettlement.waitForDeployment();

        // 设置拍卖合约地址
        await crossChainMessenger.setAuctionContract(await auctionHouse.getAddress());

        // 铸造NFT
        await nftContract.mint(owner.address, "ipfs://test");
        await nftContract.approve(await auctionHouse.getAddress(), 1);
    });

    describe("跨链拍卖创建", function () {
        it("应该能够创建跨链拍卖", async function () {
            // 创建拍卖
            await auctionHouse.createAuction(
                await nftContract.getAddress(),
                1,
                ethers.parseEther("1"),
                ethers.parseEther("2"),
                3600,
                ethers.parseEther("0.1")
            );

            const auction = await auctionHouse.auctions(1);
            expect(auction.seller).to.equal(owner.address);
            expect(auction.startingPrice).to.equal(ethers.parseEther("1"));
        });

        it("应该能够配置跨链网络", async function () {
            // 设置管理员角色
            await networkManager.grantRole(await networkManager.DEFAULT_ADMIN_ROLE(), owner.address);
            await networkManager.grantRole(await networkManager.NETWORK_ADMIN_ROLE(), owner.address);

            // 添加网络配置
            const networkConfig = {
                chainId: 1,
                name: "Ethereum",
                rpcUrl: "https://eth.llamarpc.com",
                ccipRouter: await mockRouter.getAddress(),
                linkToken: await mockLinkToken.getAddress(),
                gasLimit: 500000,
                gasPrice: 20000000000,
                isActive: true,
                isTestnet: false,
                blockConfirmations: 12,
                maxMessageSize: 1024,
                addedAt: 0,
                lastUpdated: 0
            };

            await networkManager.addNetwork(networkConfig);
            
            const config = await networkManager.networkConfigs(1);
            expect(config.name).to.equal("Ethereum");
            expect(config.isActive).to.be.true;
        });
    });

    describe("跨链出价处理", function () {
        beforeEach(async function () {
            // 创建拍卖
            await auctionHouse.createAuction(
                await nftContract.getAddress(),
                1,
                ethers.parseEther("1"),
                ethers.parseEther("2"),
                3600,
                ethers.parseEther("0.1")
            );
        });

        it("应该能够处理本地出价", async function () {
            // 本地出价
            await auctionHouse.connect(bidder1).placeBid(1, {
                value: ethers.parseEther("2")
            });

            const auction = await auctionHouse.auctions(1);
            expect(auction.currentBidder).to.equal(bidder1.address);
            expect(auction.currentBid).to.equal(ethers.parseEther("2"));
        });

        it("应该能够托管跨链出价资金", async function () {
            // 托管出价资金
            await bidSettlement.connect(bidder1).escrowBid(
                1, // auctionId
                ethers.parseEther("2"), // amount
                ethers.ZeroAddress, // ETH
                2, // targetChainId
                { value: ethers.parseEther("2") }
            );

            const escrow = await bidSettlement.escrows(1);
            expect(escrow.bidder).to.equal(bidder1.address);
            expect(escrow.amount).to.equal(ethers.parseEther("2"));
            expect(escrow.isActive).to.be.true;
        });
    });

    describe("跨链消息传递", function () {
        it("应该能够发送跨链消息", async function () {
            // 设置链配置
            const chainConfig = {
                chainId: 2,
                ccipRouter: await mockRouter.getAddress(),
                linkToken: await mockLinkToken.getAddress(),
                auctionContract: await auctionHouse.getAddress(),
                isSupported: true,
                gasLimit: 500000,
                extraArgs: "0x"
            };

            await crossChainMessenger.setChainConfig(2, chainConfig);

            // 构造跨链消息
            const message = {
                messageType: 1,
                auctionId: 1,
                sender: bidder1.address,
                data: ethers.AbiCoder.defaultAbiCoder().encode(
                    ["address", "uint256", "address"],
                    [bidder1.address, ethers.parseEther("2"), ethers.ZeroAddress]
                ),
                sourceChainId: 1,
                destinationChainId: 2,
                timestamp: Math.floor(Date.now() / 1000)
            };

            // 发送消息（需要足够的LINK代币）
            await mockLinkToken.transfer(await crossChainMessenger.getAddress(), ethers.parseEther("10"));
            
            await expect(
                crossChainMessenger.sendMessage(2, message)
            ).to.not.be.reverted;
        });
    });

    describe("跨链拍卖结算", function () {
        beforeEach(async function () {
            // 创建拍卖
            await auctionHouse.createAuction(
                await nftContract.getAddress(),
                1,
                ethers.parseEther("1"),
                ethers.parseEther("2"),
                3600,
                ethers.parseEther("0.1")
            );

            // 托管出价
            await bidSettlement.connect(bidder1).escrowBid(
                1,
                ethers.parseEther("2"),
                ethers.ZeroAddress,
                2,
                { value: ethers.parseEther("2") }
            );
        });

        it("应该能够释放托管资金", async function () {
            const initialBalance = await ethers.provider.getBalance(bidder1.address);
            
            // 释放托管资金
            await bidSettlement.releaseBid(1);
            
            const escrow = await bidSettlement.escrows(1);
            expect(escrow.isActive).to.be.false;
        });

        it("应该能够处理拍卖结算", async function () {
            // 结束拍卖
            await ethers.provider.send("evm_increaseTime", [3700]);
            await ethers.provider.send("evm_mine", []);

            // 验证拍卖状态
            const auction = await auctionHouse.getAuction(1);
            expect(auction.status).to.equal(1); // Active status
        });
    });

    describe("网络管理和故障恢复", function () {
        it("应该能够管理网络状态", async function () {
            // 设置管理员角色
            await networkManager.grantRole(await networkManager.DEFAULT_ADMIN_ROLE(), owner.address);
            await networkManager.grantRole(await networkManager.NETWORK_ADMIN_ROLE(), owner.address);

            // 添加网络
            const networkConfig = {
                chainId: 3,
                name: "BSC",
                rpcUrl: "https://bsc.llamarpc.com",
                ccipRouter: await mockRouter.getAddress(),
                linkToken: await mockLinkToken.getAddress(),
                gasLimit: 500000,
                gasPrice: 5000000000,
                isActive: true,
                isTestnet: false,
                blockConfirmations: 3,
                maxMessageSize: 1024,
                addedAt: 0,
                lastUpdated: 0
            };

            await networkManager.addNetwork(networkConfig);
            
            // 验证网络配置
            const config = await networkManager.networkConfigs(3);
            expect(config.name).to.equal("BSC");
            expect(config.isActive).to.be.true;

            // 更新网络配置
            networkConfig.gasPrice = 6000000000;
            await networkManager.updateNetwork(3, networkConfig);
            
            const updatedConfig = await networkManager.networkConfigs(3);
            expect(updatedConfig.gasPrice).to.equal(6000000000);
        });

        it("应该能够处理紧急模式", async function () {
            // 设置管理员角色
            await networkManager.grantRole(await networkManager.DEFAULT_ADMIN_ROLE(), owner.address);
            
            // 启用紧急模式
            await networkManager.setEmergencyMode(true);
            expect(await networkManager.emergencyMode()).to.be.true;
            
            // 禁用紧急模式
            await networkManager.setEmergencyMode(false);
            expect(await networkManager.emergencyMode()).to.be.false;
        });
    });

    describe("安全性测试", function () {
        it("应该拒绝未授权的操作", async function () {
            // 非所有者尝试设置拍卖合约
            await expect(
                crossChainMessenger.connect(bidder1).setAuctionContract(bidder1.address)
            ).to.be.revertedWithCustomError(crossChainMessenger, "OwnableUnauthorizedAccount");
        });

        it("应该验证消息完整性", async function () {
            // 设置链配置
            const chainConfig = {
                chainId: 2,
                ccipRouter: await mockRouter.getAddress(),
                linkToken: await mockLinkToken.getAddress(),
                auctionContract: await auctionHouse.getAddress(),
                isSupported: true,
                gasLimit: 500000,
                extraArgs: "0x"
            };

            await crossChainMessenger.setChainConfig(2, chainConfig);

            // 尝试发送无效消息
            const invalidMessage = {
                messageType: 999, // 无效类型
                auctionId: 0,
                sender: ethers.ZeroAddress,
                data: ethers.AbiCoder.defaultAbiCoder().encode(
                    ["address", "uint256", "address"],
                    [ethers.ZeroAddress, 0, ethers.ZeroAddress]
                ),
                sourceChainId: 1,
                destinationChainId: 2,
                timestamp: 0
            };

            await expect(
                crossChainMessenger.sendMessage(2, invalidMessage)
            ).to.be.reverted;
        });
    });
});