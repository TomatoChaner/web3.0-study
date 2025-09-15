import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { AuctionFactory, AuctionHouse, PriceOracle, AuctionNFT } from "../../typechain-types";

describe("AuctionWithOracle Integration Tests", function () {
    let auctionFactory: AuctionFactory;
    let auctionHouse: AuctionHouse;
    let priceOracle: PriceOracle;
    let mockNFT: AuctionNFT;
    let owner: SignerWithAddress;
    let seller: SignerWithAddress;
    let bidder: SignerWithAddress;
    let bidder2: SignerWithAddress;
    let feeRecipient: SignerWithAddress;
    let auctionHouseAddress: string;

    // ETH价格为2000美元，所以:
    // 1000 USD = 0.5 ETH
    // 1500 USD = 0.75 ETH  
    // 100 USD = 0.05 ETH
    const STARTING_PRICE = ethers.parseEther("0.5"); // 0.5 ETH (1000 USD)
    const RESERVE_PRICE = ethers.parseEther("0.75"); // 0.75 ETH (1500 USD)
    const BID_INCREMENT = ethers.parseEther("0.05"); // 0.05 ETH (100 USD)
    const DURATION = 3600; // 1 hour

    beforeEach(async function () {
        [owner, seller, bidder, bidder2, feeRecipient] = await ethers.getSigners();

        // 部署价格预言机
        const PriceOracle = await ethers.getContractFactory("PriceOracle");
        priceOracle = await PriceOracle.deploy();

        // 部署拍卖工厂
        const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
        auctionFactory = await AuctionFactory.deploy(
            feeRecipient.address,
            await priceOracle.getAddress()
        );

        // 部署AuctionNFT
        const AuctionNFTFactory = await ethers.getContractFactory("AuctionNFT");
        mockNFT = await AuctionNFTFactory.deploy("Test NFT", "TNFT");

        // 设置NFT支持
        await auctionFactory.setNFTSupport(await mockNFT.getAddress(), true);

        // 创建拍卖行
        const tx = await auctionFactory.createAuctionHouse(
            await mockNFT.getAddress(),
            "Test Auction House",
            0,
            "0x"
        );
        const receipt = await tx.wait();
        const event = receipt?.logs.find((log: any) => {
            try {
                return auctionFactory.interface.parseLog(log)?.name === "AuctionHouseCreated";
            } catch {
                return false;
            }
        });

        if (event) {
            const parsedEvent = auctionFactory.interface.parseLog(event);
            auctionHouseAddress = parsedEvent?.args[0];
        }

        auctionHouse = await ethers.getContractAt("AuctionHouse", auctionHouseAddress);

        // 添加ETH价格数据源
        await priceOracle.addPriceFeed(
            ethers.ZeroAddress,
            "0x1111111111111111111111111111111111111111", // mock feed address
            3600, // 1 hour heartbeat
            "ETH/USD Price Feed"
        );
    });

    describe("价格预言机集成", function () {
        it("应该正确设置价格预言机", async function () {
            const oracleAddress = await auctionHouse.priceOracle();
            expect(oracleAddress).to.equal(await priceOracle.getAddress());
        });

        it("应该能够更新价格预言机", async function () {
            // 部署新的价格预言机
            const newPriceOracle = await ethers.deployContract("PriceOracle");
            
            // 检查AuctionHouse的实际owner
            const auctionHouseOwner = await auctionHouse.owner();
            console.log("AuctionHouse owner:", auctionHouseOwner);
            console.log("Factory owner:", owner.address);
            console.log("Seller address:", seller.address);
            
            // 获取当前价格预言机地址
             const oldOracleAddress = await auctionHouse.priceOracle();
             
             // 使用AuctionFactory的owner权限更新价格预言机
             await expect(auctionHouse.connect(owner).setPriceOracle(await newPriceOracle.getAddress()))
                 .to.emit(auctionHouse, "PriceOracleUpdated")
                 .withArgs(oldOracleAddress, await newPriceOracle.getAddress());
            
            expect(await auctionHouse.priceOracle()).to.equal(await newPriceOracle.getAddress());
        });
    });

    describe("多币种出价功能", function () {
        beforeEach(async function () {
            // Mint NFT给seller
            await mockNFT.connect(owner).mint(seller.address, "https://example.com/token/1");
            await mockNFT.connect(seller).approve(auctionHouseAddress, 0);

            // 创建拍卖
            await auctionHouse.connect(seller).createAuction(
                await mockNFT.getAddress(),
                0,
                STARTING_PRICE,
                RESERVE_PRICE,
                DURATION,
                BID_INCREMENT
            );
        });

        it("应该支持ETH出价", async function () {
            // 使用ETH出价 - 1 ETH高于保留价0.75 ETH
            await expect(
                auctionHouse.connect(bidder).placeBid(0, { value: ethers.parseEther("1.0") })
            ).to.emit(auctionHouse, "BidPlaced");

            const auction = await auctionHouse.auctions(0);
            expect(auction.currentBid).to.equal(ethers.parseEther("1.0"));
            expect(auction.currentBidder).to.equal(bidder.address);
            expect(auction.bidToken).to.equal(ethers.ZeroAddress);
        });

        it("应该正确转换ETH到USD价值", async function () {
            const ethAmount = ethers.parseEther("1");
            const usdValue = await auctionHouse.getTokenValueInUSD(ethers.ZeroAddress, ethAmount);
            expect(usdValue).to.be.gt(0);
        });
    });

    describe("拍卖结算", function () {
        let settlementTokenId: number;
        
        beforeEach(async function () {
            // Mint NFT给seller
            const tx = await mockNFT.connect(owner).mint(seller.address, "https://example.com/token/settlement");
            const receipt = await tx.wait();
            const mintEvent = receipt?.logs.find(log => {
                try {
                    const parsed = mockNFT.interface.parseLog(log);
                    return parsed?.name === 'TokenMinted';
                } catch {
                    return false;
                }
            });
            if (mintEvent) {
                const parsed = mockNFT.interface.parseLog(mintEvent);
                settlementTokenId = parsed?.args[1];
            }
            
            await mockNFT.connect(seller).approve(auctionHouseAddress, settlementTokenId);

            // 创建拍卖
            await auctionHouse.connect(seller).createAuction(
                await mockNFT.getAddress(),
                settlementTokenId,
                STARTING_PRICE,
                RESERVE_PRICE,
                DURATION,
                BID_INCREMENT
            );
        });

        it("应该正确结算ETH拍卖", async function () {
            // ETH出价
            await auctionHouse.connect(bidder).placeBid(settlementTokenId, { value: ethers.parseEther("1.0") });

            // 快进时间
            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine", []);

            // 结束拍卖
            await expect(auctionHouse.endAuction(settlementTokenId))
                .to.emit(auctionHouse, "AuctionEnded");

            // 检查NFT所有者
            expect(await mockNFT.ownerOf(settlementTokenId)).to.equal(bidder.address);
        });

        it("应该在未达到保留价时退还NFT", async function () {
            // 低价出价（低于reserve price但高于starting price）
             await auctionHouse.connect(bidder).placeBid(settlementTokenId, { value: ethers.parseEther("0.6") }); // 0.6 ETH < 0.75 ETH保留价

            // 快进时间
            await ethers.provider.send("evm_increaseTime", [3600]);
            await ethers.provider.send("evm_mine", []);

            // 结束拍卖
            await auctionHouse.endAuction(settlementTokenId);

            // NFT应该退还给seller
            expect(await mockNFT.ownerOf(settlementTokenId)).to.equal(seller.address);
        });
    });

    describe("USD价值查询", function () {
        let usdTokenId: number;
        
        beforeEach(async function () {
            // Mint NFT给seller
            const tx = await mockNFT.connect(owner).mint(seller.address, "https://example.com/token/usd");
            const receipt = await tx.wait();
            const mintEvent = receipt?.logs.find(log => {
                try {
                    const parsed = mockNFT.interface.parseLog(log);
                    return parsed?.name === 'TokenMinted';
                } catch {
                    return false;
                }
            });
            if (mintEvent) {
                const parsed = mockNFT.interface.parseLog(mintEvent);
                usdTokenId = parsed?.args[1];
            }
            
            await mockNFT.connect(seller).approve(auctionHouseAddress, usdTokenId);

            // 创建拍卖
            await auctionHouse.connect(seller).createAuction(
                await mockNFT.getAddress(),
                usdTokenId,
                STARTING_PRICE,
                RESERVE_PRICE,
                DURATION,
                BID_INCREMENT
            );
        });

        it("应该返回正确的USD价值", async function () {
            const usdValues = await auctionHouse.getAuctionUSDValue(usdTokenId);

            expect(usdValues[0]).to.equal(STARTING_PRICE); // startingPriceUSD
            expect(usdValues[1]).to.equal(RESERVE_PRICE); // reservePriceUSD
            expect(usdValues[2]).to.equal(0); // currentBidUSD
            expect(usdValues[3]).to.equal(STARTING_PRICE); // minNextBidUSD
        });

        it("应该正确转换代币价值", async function () {
            const ethValue = await auctionHouse.getTokenValueInUSD(
                ethers.ZeroAddress,
                ethers.parseEther("1")
            );

            expect(ethValue).to.be.gt(0); // 应该大于0
        });
    });
});