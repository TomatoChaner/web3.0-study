import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { AuctionHouse, AuctionNFT } from "../../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("AuctionHouse", function () {
    // 测试用常量
    const STARTING_PRICE = ethers.parseEther("1");
    const RESERVE_PRICE = ethers.parseEther("2");
    const BID_INCREMENT = ethers.parseEther("0.1");
    const AUCTION_DURATION = 24 * 60 * 60; // 24小时
    const PLATFORM_FEE_RATE = 250; // 2.5%
    const TOKEN_ID = 0;
    const TOKEN_URI = "https://example.com/token/1";

    async function deployAuctionHouseFixture() {
        const [owner, seller, bidder1, bidder2, feeRecipient] = await ethers.getSigners();

        // 部署AuctionNFT合约
        const AuctionNFTFactory = await ethers.getContractFactory("AuctionNFT");
        const auctionNFT = await AuctionNFTFactory.deploy(
            "Auction NFT",
            "ANFT"
        );

        // 部署AuctionHouse合约
        const AuctionHouseFactory = await ethers.getContractFactory("AuctionHouse");
        const auctionHouse = await AuctionHouseFactory.deploy(feeRecipient.address);

        // 铸造NFT给seller
        await auctionNFT.connect(owner).mint(seller.address, TOKEN_URI);

        return {
            auctionHouse,
            auctionNFT,
            owner,
            seller,
            bidder1,
            bidder2,
            feeRecipient
        };
    }

    describe("部署和初始化", function () {
        it("应该正确部署合约", async function () {
            const { auctionHouse, feeRecipient } = await loadFixture(deployAuctionHouseFixture);
            
            expect(await auctionHouse.feeRecipient()).to.equal(feeRecipient.address);
            expect(await auctionHouse.platformFeeRate()).to.equal(PLATFORM_FEE_RATE);
            expect(await auctionHouse.getCurrentAuctionId()).to.equal(0);
        });

        it("应该拒绝零地址作为手续费接收者", async function () {
            const AuctionHouseFactory = await ethers.getContractFactory("AuctionHouse");
            
            await expect(
                AuctionHouseFactory.deploy(ethers.ZeroAddress)
            ).to.be.revertedWith("AuctionHouse: invalid fee recipient");
        });
    });

    describe("创建拍卖", function () {
        it("应该成功创建拍卖", async function () {
            const { auctionHouse, auctionNFT, seller } = await loadFixture(deployAuctionHouseFixture);
            
            // 授权AuctionHouse操作NFT
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            
            const tx = await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            await expect(tx)
                .to.emit(auctionHouse, "AuctionCreated")
                .withArgs(
                    0, // auctionId
                    auctionNFT.target,
                    TOKEN_ID,
                    seller.address,
                    STARTING_PRICE,
                    RESERVE_PRICE,
                    await time.latest(),
                    await time.latest() + AUCTION_DURATION
                );
            
            // 验证NFT已转移到合约
            expect(await auctionNFT.ownerOf(TOKEN_ID)).to.equal(auctionHouse.target);
            
            // 验证拍卖信息
            const auction = await auctionHouse.getAuction(0);
            expect(auction.seller).to.equal(seller.address);
            expect(auction.startingPrice).to.equal(STARTING_PRICE);
            expect(auction.reservePrice).to.equal(RESERVE_PRICE);
            expect(auction.status).to.equal(0); // Active
        });

        it("应该拒绝非NFT所有者创建拍卖", async function () {
            const { auctionHouse, auctionNFT, bidder1 } = await loadFixture(deployAuctionHouseFixture);
            
            await expect(
                auctionHouse.connect(bidder1).createAuction(
                    auctionNFT.target,
                    TOKEN_ID,
                    STARTING_PRICE,
                    RESERVE_PRICE,
                    AUCTION_DURATION,
                    BID_INCREMENT
                )
            ).to.be.revertedWith("AuctionHouse: not NFT owner");
        });

        it("应该拒绝未授权的NFT创建拍卖", async function () {
            const { auctionHouse, auctionNFT, seller } = await loadFixture(deployAuctionHouseFixture);
            
            await expect(
                auctionHouse.connect(seller).createAuction(
                    auctionNFT.target,
                    TOKEN_ID,
                    STARTING_PRICE,
                    RESERVE_PRICE,
                    AUCTION_DURATION,
                    BID_INCREMENT
                )
            ).to.be.revertedWith("AuctionHouse: NFT not approved");
        });

        it("应该拒绝无效的参数", async function () {
            const { auctionHouse, auctionNFT, seller } = await loadFixture(deployAuctionHouseFixture);
            
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            
            // 零起拍价
            await expect(
                auctionHouse.connect(seller).createAuction(
                    auctionNFT.target,
                    TOKEN_ID,
                    0,
                    RESERVE_PRICE,
                    AUCTION_DURATION,
                    BID_INCREMENT
                )
            ).to.be.revertedWith("AuctionHouse: starting price must be greater than 0");
            
            // 保留价低于起拍价
            await expect(
                auctionHouse.connect(seller).createAuction(
                    auctionNFT.target,
                    TOKEN_ID,
                    RESERVE_PRICE,
                    STARTING_PRICE,
                    AUCTION_DURATION,
                    BID_INCREMENT
                )
            ).to.be.revertedWith("AuctionHouse: reserve price must be >= starting price");
            
            // 拍卖时长过短
            await expect(
                auctionHouse.connect(seller).createAuction(
                    auctionNFT.target,
                    TOKEN_ID,
                    STARTING_PRICE,
                    RESERVE_PRICE,
                    30 * 60, // 30分钟
                    BID_INCREMENT
                )
            ).to.be.revertedWith("AuctionHouse: invalid auction duration");
        });
    });

    describe("出价功能", function () {
        async function createAuctionFixture() {
            const fixture = await loadFixture(deployAuctionHouseFixture);
            const { auctionHouse, auctionNFT, seller } = fixture;
            
            // 创建拍卖
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            return fixture;
        }

        it("应该成功出价", async function () {
            const { auctionHouse, bidder1 } = await loadFixture(createAuctionFixture);
            
            const bidAmount = STARTING_PRICE;
            
            const tx = await auctionHouse.connect(bidder1).placeBid(0, { value: bidAmount });
            
            await expect(tx)
                .to.emit(auctionHouse, "BidPlaced")
                .withArgs(0, bidder1.address, bidAmount, await time.latest());
            
            const auction = await auctionHouse.getAuction(0);
            expect(auction.currentBid).to.equal(bidAmount);
            expect(auction.currentBidder).to.equal(bidder1.address);
        });

        it("应该正确处理多次出价", async function () {
            const { auctionHouse, bidder1, bidder2 } = await loadFixture(createAuctionFixture);
            
            const firstBid = STARTING_PRICE;
            const secondBid = STARTING_PRICE + BID_INCREMENT;
            
            // 第一次出价
            await auctionHouse.connect(bidder1).placeBid(0, { value: firstBid });
            
            const bidder1BalanceBefore = await ethers.provider.getBalance(bidder1.address);
            
            // 第二次出价（应该退还第一次出价）
            await auctionHouse.connect(bidder2).placeBid(0, { value: secondBid });
            
            const bidder1BalanceAfter = await ethers.provider.getBalance(bidder1.address);
            
            // 验证第一个出价者收到退款
            expect(bidder1BalanceAfter - bidder1BalanceBefore).to.equal(firstBid);
            
            // 验证拍卖状态
            const auction = await auctionHouse.getAuction(0);
            expect(auction.currentBid).to.equal(secondBid);
            expect(auction.currentBidder).to.equal(bidder2.address);
        });

        it("应该拒绝卖家出价", async function () {
            const { auctionHouse, seller } = await loadFixture(createAuctionFixture);
            
            await expect(
                auctionHouse.connect(seller).placeBid(0, { value: STARTING_PRICE })
            ).to.be.revertedWith("AuctionHouse: seller cannot bid");
        });

        it("应该拒绝低于最小出价的金额", async function () {
            const { auctionHouse, bidder1, bidder2 } = await loadFixture(createAuctionFixture);
            
            // 第一次出价
            await auctionHouse.connect(bidder1).placeBid(0, { value: STARTING_PRICE });
            
            // 尝试出价低于最小增量
            await expect(
                auctionHouse.connect(bidder2).placeBid(0, { 
                    value: STARTING_PRICE + BID_INCREMENT - ethers.parseEther("0.01") 
                })
            ).to.be.revertedWith("AuctionHouse: bid too low");
        });

        it("应该拒绝在拍卖结束后出价", async function () {
            const { auctionHouse, bidder1 } = await loadFixture(createAuctionFixture);
            
            // 快进到拍卖结束后
            await time.increase(AUCTION_DURATION + 1);
            
            await expect(
                auctionHouse.connect(bidder1).placeBid(0, { value: STARTING_PRICE })
            ).to.be.revertedWith("AuctionHouse: auction ended");
        });
    });

    describe("结束拍卖", function () {
        async function createAuctionWithBidsFixture() {
            const fixture = await loadFixture(deployAuctionHouseFixture);
            const { auctionHouse, auctionNFT, seller, bidder1 } = fixture;
            
            // 创建拍卖
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            // 出价达到保留价
            await auctionHouse.connect(bidder1).placeBid(0, { value: RESERVE_PRICE });
            
            return fixture;
        }

        it("应该成功结束拍卖并转移NFT和资金", async function () {
            const { auctionHouse, auctionNFT, seller, bidder1, feeRecipient } = 
                await loadFixture(createAuctionWithBidsFixture);
            
            // 快进到拍卖结束
            await time.increase(AUCTION_DURATION + 1);
            
            const sellerBalanceBefore = await ethers.provider.getBalance(seller.address);
            const feeRecipientBalanceBefore = await ethers.provider.getBalance(feeRecipient.address);
            
            const tx = await auctionHouse.endAuction(0);
            
            await expect(tx)
                .to.emit(auctionHouse, "AuctionEnded")
                .withArgs(0, bidder1.address, RESERVE_PRICE, await time.latest());
            
            // 验证NFT转移
            expect(await auctionNFT.ownerOf(TOKEN_ID)).to.equal(bidder1.address);
            
            // 验证资金转移
            const platformFee = (RESERVE_PRICE * BigInt(PLATFORM_FEE_RATE)) / BigInt(10000);
            const sellerAmount = RESERVE_PRICE - platformFee;
            
            const sellerBalanceAfter = await ethers.provider.getBalance(seller.address);
            const feeRecipientBalanceAfter = await ethers.provider.getBalance(feeRecipient.address);
            
            expect(sellerBalanceAfter - sellerBalanceBefore).to.equal(sellerAmount);
            expect(feeRecipientBalanceAfter - feeRecipientBalanceBefore).to.equal(platformFee);
            
            // 验证拍卖状态
            const auction = await auctionHouse.getAuction(0);
            expect(auction.status).to.equal(1); // Ended
        });

        it("应该处理未达到保留价的拍卖", async function () {
            const { auctionHouse, auctionNFT, seller, bidder1 } = 
                await loadFixture(deployAuctionHouseFixture);
            
            // 创建拍卖
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            // 出价低于保留价
            const lowBid = STARTING_PRICE;
            await auctionHouse.connect(bidder1).placeBid(0, { value: lowBid });
            
            // 快进到拍卖结束
            await time.increase(AUCTION_DURATION + 1);
            
            const bidderBalanceBefore = await ethers.provider.getBalance(bidder1.address);
            
            await auctionHouse.endAuction(0);
            
            // 验证NFT退还给卖家
            expect(await auctionNFT.ownerOf(TOKEN_ID)).to.equal(seller.address);
            
            // 验证出价退还给出价者
            const bidderBalanceAfter = await ethers.provider.getBalance(bidder1.address);
            expect(bidderBalanceAfter - bidderBalanceBefore).to.equal(lowBid);
        });

        it("应该拒绝在拍卖未结束时结束拍卖", async function () {
            const { auctionHouse } = await loadFixture(createAuctionWithBidsFixture);
            
            await expect(
                auctionHouse.endAuction(0)
            ).to.be.revertedWith("AuctionHouse: auction not ended");
        });
    });

    describe("取消拍卖", function () {
        it("应该允许卖家取消无人出价的拍卖", async function () {
            const { auctionHouse, auctionNFT, seller } = await loadFixture(deployAuctionHouseFixture);
            
            // 创建拍卖
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            const tx = await auctionHouse.connect(seller).cancelAuction(0);
            
            await expect(tx)
                .to.emit(auctionHouse, "AuctionCancelled")
                .withArgs(0, seller.address, await time.latest());
            
            // 验证NFT退还给卖家
            expect(await auctionNFT.ownerOf(TOKEN_ID)).to.equal(seller.address);
            
            // 验证拍卖状态
            const auction = await auctionHouse.getAuction(0);
            expect(auction.status).to.equal(2); // Cancelled
        });

        it("应该拒绝非卖家取消拍卖", async function () {
            const { auctionHouse, auctionNFT, seller, bidder1 } = 
                await loadFixture(deployAuctionHouseFixture);
            
            // 创建拍卖
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            await expect(
                auctionHouse.connect(bidder1).cancelAuction(0)
            ).to.be.revertedWith("AuctionHouse: only seller can cancel");
        });

        it("应该拒绝取消有出价的拍卖", async function () {
            const { auctionHouse, auctionNFT, seller, bidder1 } = 
                await loadFixture(deployAuctionHouseFixture);
            
            // 创建拍卖
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            // 出价
            await auctionHouse.connect(bidder1).placeBid(0, { value: STARTING_PRICE });
            
            await expect(
                auctionHouse.connect(seller).cancelAuction(0)
            ).to.be.revertedWith("AuctionHouse: cannot cancel with bids");
        });
    });

    describe("管理功能", function () {
        it("应该允许所有者设置平台手续费率", async function () {
            const { auctionHouse, owner } = await loadFixture(deployAuctionHouseFixture);
            
            const newFeeRate = 500; // 5%
            
            await expect(
                auctionHouse.connect(owner).setPlatformFeeRate(newFeeRate)
            ).to.emit(auctionHouse, "PlatformFeeUpdated")
            .withArgs(PLATFORM_FEE_RATE, newFeeRate);
            
            expect(await auctionHouse.platformFeeRate()).to.equal(newFeeRate);
        });

        it("应该拒绝设置过高的手续费率", async function () {
            const { auctionHouse, owner } = await loadFixture(deployAuctionHouseFixture);
            
            await expect(
                auctionHouse.connect(owner).setPlatformFeeRate(1001) // >10%
            ).to.be.revertedWith("AuctionHouse: fee rate too high");
        });

        it("应该允许所有者设置手续费接收地址", async function () {
            const { auctionHouse, owner, bidder1 } = await loadFixture(deployAuctionHouseFixture);
            
            await expect(
                auctionHouse.connect(owner).setFeeRecipient(bidder1.address)
            ).to.emit(auctionHouse, "FeeRecipientUpdated");
            
            expect(await auctionHouse.feeRecipient()).to.equal(bidder1.address);
        });

        it("应该允许所有者暂停和恢复合约", async function () {
            const { auctionHouse, owner } = await loadFixture(deployAuctionHouseFixture);
            
            await auctionHouse.connect(owner).pause();
            expect(await auctionHouse.paused()).to.be.true;
            
            await auctionHouse.connect(owner).unpause();
            expect(await auctionHouse.paused()).to.be.false;
        });
    });

    describe("查询功能", function () {
        it("应该正确返回用户拍卖列表", async function () {
            const { auctionHouse, auctionNFT, seller } = await loadFixture(deployAuctionHouseFixture);
            
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            const userAuctions = await auctionHouse.getUserAuctions(seller.address);
            expect(userAuctions).to.have.lengthOf(1);
            expect(userAuctions[0]).to.equal(0);
        });

        it("应该正确返回用户出价列表", async function () {
            const { auctionHouse, auctionNFT, seller, bidder1 } = 
                await loadFixture(deployAuctionHouseFixture);
            
            await auctionNFT.connect(seller).setApprovalForAll(auctionHouse.target, true);
            await auctionHouse.connect(seller).createAuction(
                auctionNFT.target,
                TOKEN_ID,
                STARTING_PRICE,
                RESERVE_PRICE,
                AUCTION_DURATION,
                BID_INCREMENT
            );
            
            await auctionHouse.connect(bidder1).placeBid(0, { value: STARTING_PRICE });
            
            const userBids = await auctionHouse.getUserBids(bidder1.address);
            expect(userBids).to.have.lengthOf(1);
            expect(userBids[0]).to.equal(0);
        });
    });
});