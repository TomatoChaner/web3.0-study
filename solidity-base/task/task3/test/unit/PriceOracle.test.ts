import { expect } from "chai";
import { ethers } from "hardhat";
import { PriceOracle } from "../../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("PriceOracle", function () {
  let priceOracle: PriceOracle;
  let mockToken: any;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let otherUser: SignerWithAddress;

  const ETH_ADDRESS = "0x0000000000000000000000000000000000000000";
  const MOCK_FEED_ADDRESS = "0x1111111111111111111111111111111111111111";
  const ETH_FEED_ADDRESS = "0x2222222222222222222222222222222222222222";
  const HEARTBEAT = 3600; // 1 hour

  beforeEach(async function () {
    [owner, user, otherUser] = await ethers.getSigners();

    // 创建简单的测试代币地址
    mockToken = {
      getAddress: async () => "0x9999999999999999999999999999999999999999"
    };

    // 部署PriceOracle
    const PriceOracleFactory = await ethers.getContractFactory("PriceOracle");
    priceOracle = await PriceOracleFactory.deploy();

    // 添加价格数据源
    await priceOracle.addPriceFeed(
      ETH_ADDRESS,
      ETH_FEED_ADDRESS,
      HEARTBEAT,
      "ETH/USD Price Feed"
    );
    
    await priceOracle.addPriceFeed(
      await mockToken.getAddress(),
      MOCK_FEED_ADDRESS,
      HEARTBEAT,
      "MOCK/USD Price Feed"
    );
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await priceOracle.owner()).to.equal(owner.address);
    });

    it("Should return correct version", async function () {
      expect(await priceOracle.version()).to.equal("1.0.0");
    });

    it("Should not be paused initially", async function () {
      expect(await priceOracle.paused()).to.be.false;
    });
  });

  describe("Price Feed Management", function () {
    it("Should add price feed correctly", async function () {
      const newTokenAddress = "0x1234567890123456789012345678901234567890";
      const newFeedAddress = "0x3333333333333333333333333333333333333333";
      const description = "New Token Price Feed";

      await expect(
        priceOracle.addPriceFeed(newTokenAddress, newFeedAddress, HEARTBEAT, description)
      )
        .to.emit(priceOracle, "PriceFeedAdded")
        .withArgs(newTokenAddress, newFeedAddress, description);

      const priceFeed = await priceOracle.getPriceFeed(newTokenAddress);
      expect(priceFeed.feedAddress).to.equal(newFeedAddress);
      expect(priceFeed.description).to.equal(description);
      expect(priceFeed.active).to.be.true;
    });

    it("Should not allow non-owner to add price feed", async function () {
      const newTokenAddress = "0x1234567890123456789012345678901234567890";
      const newFeedAddress = "0x3333333333333333333333333333333333333333";
      const description = "New Token Price Feed";

      await expect(
        priceOracle.connect(user).addPriceFeed(newTokenAddress, newFeedAddress, HEARTBEAT, description)
      ).to.be.revertedWithCustomError(priceOracle, "OwnableUnauthorizedAccount");
    });

    it("Should update price feed correctly", async function () {
      const newFeedAddress = "0x4444444444444444444444444444444444444444";
      const newDescription = "Updated ETH Price Feed";

      await expect(
        priceOracle.updatePriceFeed(ETH_ADDRESS, newFeedAddress, HEARTBEAT, newDescription)
      )
        .to.emit(priceOracle, "PriceFeedUpdated")
        .withArgs(ETH_ADDRESS, ETH_FEED_ADDRESS, newFeedAddress);

      const priceFeed = await priceOracle.getPriceFeed(ETH_ADDRESS);
      expect(priceFeed.feedAddress).to.equal(newFeedAddress);
      expect(priceFeed.description).to.equal(newDescription);
    });

    it("Should deactivate price feed correctly", async function () {
      await expect(priceOracle.deactivatePriceFeed(ETH_ADDRESS))
        .to.emit(priceOracle, "PriceFeedDeactivated")
        .withArgs(ETH_ADDRESS, ETH_FEED_ADDRESS);

      const priceFeed = await priceOracle.getPriceFeed(ETH_ADDRESS);
      expect(priceFeed.active).to.be.false;
    });

    it("Should check if price feed is healthy", async function () {
      const [available, fresh] = await priceOracle.isPriceFeedHealthy(ETH_ADDRESS);
      expect(available).to.be.true;
      
      await priceOracle.deactivatePriceFeed(ETH_ADDRESS);
      const [availableAfter, freshAfter] = await priceOracle.isPriceFeedHealthy(ETH_ADDRESS);
      expect(availableAfter).to.be.false;
    });
  });

  describe("Price Queries", function () {
    it("Should return latest price correctly", async function () {
      const [price, timestamp] = await priceOracle.getLatestPrice(ETH_ADDRESS);
      expect(price).to.be.gt(0);
      expect(timestamp).to.be.gt(0);
    });

    it("Should revert for unsupported token", async function () {
      const unsupportedToken = "0x1234567890123456789012345678901234567890";
      await expect(
        priceOracle.getLatestPrice(unsupportedToken)
      ).to.be.revertedWith("PriceOracle: price feed not found");
    });

    it("Should return historical price (placeholder)", async function () {
      const [price, actualTimestamp] = await priceOracle.getHistoricalPrice(
        ETH_ADDRESS,
        Math.floor(Date.now() / 1000)
      );
      expect(price).to.be.gt(0);
      expect(actualTimestamp).to.be.gt(0);
    });

    it("Should convert price between tokens correctly", async function () {
      // Convert 1 ETH to MOCK tokens based on oracle prices
      const ethAmount = ethers.parseUnits("1", 18);
      
      const convertedAmount = await priceOracle.convertPrice(
        ETH_ADDRESS,
        await mockToken.getAddress(),
        ethAmount
      );
      
      expect(convertedAmount).to.be.gt(0);
    });

    it("Should get USD value correctly", async function () {
      const tokenAmount = ethers.parseUnits("100", 18);
      
      const usdValue = await priceOracle.getUSDValue(
        await mockToken.getAddress(),
        tokenAmount
      );
      
      expect(usdValue).to.be.gt(0);
    });
  });

  describe("Access Control", function () {
    it("Should return correct admin address", async function () {
      expect(await priceOracle.admin()).to.equal(owner.address);
    });

    it("Should pause and unpause correctly", async function () {
      await priceOracle.pause();
      expect(await priceOracle.paused()).to.be.true;

      await priceOracle.unpause();
      expect(await priceOracle.paused()).to.be.false;
    });

    it("Should not allow non-owner to pause", async function () {
      await expect(
        priceOracle.connect(user).pause()
      ).to.be.revertedWithCustomError(priceOracle, "OwnableUnauthorizedAccount");
    });
  });

  describe("Edge Cases", function () {
    it("Should handle invalid heartbeat correctly", async function () {
      await expect(
        priceOracle.addPriceFeed(
          "0x1234567890123456789012345678901234567890",
          "0x5555555555555555555555555555555555555555",
          0,
          "Invalid Heartbeat Feed"
        )
      ).to.be.revertedWith("PriceOracle: invalid heartbeat");
    });

    it("Should handle price conversion with zero amount", async function () {
      const convertedAmount = await priceOracle.convertPrice(
        ETH_ADDRESS,
        await mockToken.getAddress(),
        0
      );
      
      expect(convertedAmount).to.equal(0);
    });

    it("Should handle same token conversion", async function () {
      const amount = ethers.parseUnits("100", 18);
      const convertedAmount = await priceOracle.convertPrice(
        ETH_ADDRESS,
        ETH_ADDRESS,
        amount
      );
      
      expect(convertedAmount).to.equal(amount);
    });

    it("Should revert when paused", async function () {
      await priceOracle.pause();
      
      await expect(
        priceOracle.getLatestPrice(ETH_ADDRESS)
      ).to.be.revertedWithCustomError(priceOracle, "EnforcedPause");
    });
  });

  describe("Events", function () {
    it("Should emit PriceFeedAdded event", async function () {
      const tokenAddress = "0x1234567890123456789012345678901234567890";
      const feedAddress = "0x5555555555555555555555555555555555555555";
      const description = "Test Token";

      await expect(
        priceOracle.addPriceFeed(tokenAddress, feedAddress, HEARTBEAT, description)
      )
        .to.emit(priceOracle, "PriceFeedAdded")
        .withArgs(tokenAddress, feedAddress, description);
    });

    it("Should emit PriceFeedUpdated event", async function () {
      const newFeedAddress = "0x6666666666666666666666666666666666666666";
      const newDescription = "Updated ETH Feed";

      await expect(
        priceOracle.updatePriceFeed(ETH_ADDRESS, newFeedAddress, HEARTBEAT, newDescription)
      )
        .to.emit(priceOracle, "PriceFeedUpdated")
        .withArgs(ETH_ADDRESS, ETH_FEED_ADDRESS, newFeedAddress);
    });

    it("Should emit PriceFeedDeactivated event", async function () {
      await expect(priceOracle.deactivatePriceFeed(ETH_ADDRESS))
        .to.emit(priceOracle, "PriceFeedDeactivated")
        .withArgs(ETH_ADDRESS);
    });
  });
});