import { expect } from "chai";
import { ethers } from "hardhat";
import { AuctionNFT } from "../../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("AuctionNFT", function () {
  let auctionNFT: AuctionNFT;
  let owner: HardhatEthersSigner;
  let minter: HardhatEthersSigner;
  let user1: HardhatEthersSigner;
  let user2: HardhatEthersSigner;
  let auctionContract: HardhatEthersSigner;

  const NFT_NAME = "Auction NFT";
  const NFT_SYMBOL = "ANFT";
  const TOKEN_URI = "https://example.com/token/1";
  const TOKEN_URI_2 = "https://example.com/token/2";

  beforeEach(async function () {
    [owner, minter, user1, user2, auctionContract] = await ethers.getSigners();

    const AuctionNFTFactory = await ethers.getContractFactory("AuctionNFT");
    auctionNFT = await AuctionNFTFactory.deploy(NFT_NAME, NFT_SYMBOL);
    await auctionNFT.waitForDeployment();
  });

  describe("部署", function () {
    it("应该正确设置名称和符号", async function () {
      expect(await auctionNFT.name()).to.equal(NFT_NAME);
      expect(await auctionNFT.symbol()).to.equal(NFT_SYMBOL);
    });

    it("应该设置部署者为所有者和初始铸造者", async function () {
      expect(await auctionNFT.owner()).to.equal(owner.address);
      expect(await auctionNFT.minters(owner.address)).to.be.true;
    });

    it("应该初始化代币计数器为0", async function () {
      expect(await auctionNFT.getNextTokenId()).to.equal(0);
      expect(await auctionNFT.totalSupply()).to.equal(0);
    });
  });

  describe("铸造者权限管理", function () {
    it("所有者应该能够添加铸造者", async function () {
      await expect(auctionNFT.addMinter(minter.address))
        .to.emit(auctionNFT, "MinterAdded")
        .withArgs(minter.address);
      
      expect(await auctionNFT.minters(minter.address)).to.be.true;
    });

    it("所有者应该能够移除铸造者", async function () {
      await auctionNFT.addMinter(minter.address);
      
      await expect(auctionNFT.removeMinter(minter.address))
        .to.emit(auctionNFT, "MinterRemoved")
        .withArgs(minter.address);
      
      expect(await auctionNFT.minters(minter.address)).to.be.false;
    });

    it("非所有者不应该能够添加铸造者", async function () {
      await expect(auctionNFT.connect(user1).addMinter(minter.address))
        .to.be.revertedWithCustomError(auctionNFT, "OwnableUnauthorizedAccount");
    });

    it("不应该能够添加零地址作为铸造者", async function () {
      await expect(auctionNFT.addMinter(ethers.ZeroAddress))
        .to.be.revertedWith("AuctionNFT: minter cannot be zero address");
    });

    it("不应该能够重复添加同一个铸造者", async function () {
      await auctionNFT.addMinter(minter.address);
      await expect(auctionNFT.addMinter(minter.address))
        .to.be.revertedWith("AuctionNFT: address is already a minter");
    });

    it("不应该能够移除不是铸造者的地址", async function () {
      await expect(auctionNFT.removeMinter(user1.address))
        .to.be.revertedWith("AuctionNFT: address is not a minter");
    });
  });

  describe("NFT铸造功能", function () {
    beforeEach(async function () {
      await auctionNFT.addMinter(minter.address);
    });

    it("铸造者应该能够铸造NFT", async function () {
      await expect(auctionNFT.connect(minter).mint(user1.address, TOKEN_URI))
        .to.emit(auctionNFT, "TokenMinted")
        .withArgs(user1.address, 0, TOKEN_URI);
      
      expect(await auctionNFT.ownerOf(0)).to.equal(user1.address);
      expect(await auctionNFT.tokenURI(0)).to.equal(TOKEN_URI);
      expect(await auctionNFT.totalSupply()).to.equal(1);
      expect(await auctionNFT.getNextTokenId()).to.equal(1);
    });

    it("非铸造者不应该能够铸造NFT", async function () {
      await expect(auctionNFT.connect(user1).mint(user2.address, TOKEN_URI))
        .to.be.revertedWith("AuctionNFT: caller is not a minter");
    });

    it("不应该能够铸造给零地址", async function () {
      await expect(auctionNFT.connect(minter).mint(ethers.ZeroAddress, TOKEN_URI))
        .to.be.revertedWith("AuctionNFT: cannot mint to zero address");
    });

    it("不应该能够使用空的tokenURI铸造", async function () {
      await expect(auctionNFT.connect(minter).mint(user1.address, ""))
        .to.be.revertedWith("AuctionNFT: tokenURI cannot be empty");
    });

    it("应该正确递增代币ID", async function () {
      await auctionNFT.connect(minter).mint(user1.address, TOKEN_URI);
      await auctionNFT.connect(minter).mint(user2.address, TOKEN_URI_2);
      
      expect(await auctionNFT.ownerOf(0)).to.equal(user1.address);
      expect(await auctionNFT.ownerOf(1)).to.equal(user2.address);
      expect(await auctionNFT.totalSupply()).to.equal(2);
    });
  });

  describe("批量铸造功能", function () {
    beforeEach(async function () {
      await auctionNFT.addMinter(minter.address);
    });

    it("应该能够批量铸造NFT", async function () {
      const tokenURIs = [TOKEN_URI, TOKEN_URI_2, "https://example.com/token/3"];
      
      const tx = await auctionNFT.connect(minter).mintBatch(user1.address, tokenURIs);
      const receipt = await tx.wait();
      
      // 检查事件
      const events = receipt?.logs.filter(log => {
        try {
          return auctionNFT.interface.parseLog(log)?.name === "TokenMinted";
        } catch {
          return false;
        }
      });
      expect(events).to.have.length(3);
      
      // 检查所有权
      expect(await auctionNFT.ownerOf(0)).to.equal(user1.address);
      expect(await auctionNFT.ownerOf(1)).to.equal(user1.address);
      expect(await auctionNFT.ownerOf(2)).to.equal(user1.address);
      
      // 检查URI
      expect(await auctionNFT.tokenURI(0)).to.equal(tokenURIs[0]);
      expect(await auctionNFT.tokenURI(1)).to.equal(tokenURIs[1]);
      expect(await auctionNFT.tokenURI(2)).to.equal(tokenURIs[2]);
      
      expect(await auctionNFT.totalSupply()).to.equal(3);
    });

    it("不应该能够批量铸造空数组", async function () {
      await expect(auctionNFT.connect(minter).mintBatch(user1.address, []))
        .to.be.revertedWith("AuctionNFT: tokenURIs array cannot be empty");
    });

    it("不应该能够批量铸造超过100个NFT", async function () {
      const tokenURIs = new Array(101).fill(TOKEN_URI);
      await expect(auctionNFT.connect(minter).mintBatch(user1.address, tokenURIs))
        .to.be.revertedWith("AuctionNFT: can mint at most 100 NFTs at once");
    });

    it("批量铸造中不应该包含空URI", async function () {
      const tokenURIs = [TOKEN_URI, "", TOKEN_URI_2];
      await expect(auctionNFT.connect(minter).mintBatch(user1.address, tokenURIs))
        .to.be.revertedWith("AuctionNFT: tokenURI cannot be empty");
    });
  });

  describe("NFT销毁功能", function () {
    beforeEach(async function () {
      await auctionNFT.addMinter(minter.address);
      await auctionNFT.connect(minter).mint(user1.address, TOKEN_URI);
    });

    it("所有者应该能够销毁自己的NFT", async function () {
      await expect(auctionNFT.connect(user1).burn(0))
        .to.emit(auctionNFT, "TokenBurned")
        .withArgs(0);
      
      await expect(auctionNFT.ownerOf(0))
        .to.be.revertedWithCustomError(auctionNFT, "ERC721NonexistentToken");
    });

    it("授权者应该能够销毁NFT", async function () {
      await auctionNFT.connect(user1).approve(user2.address, 0);
      
      await expect(auctionNFT.connect(user2).burn(0))
        .to.emit(auctionNFT, "TokenBurned")
        .withArgs(0);
    });

    it("非所有者和非授权者不应该能够销毁NFT", async function () {
      await expect(auctionNFT.connect(user2).burn(0))
        .to.be.revertedWith("AuctionNFT: caller is not owner nor approved");
    });

    it("销毁NFT应该清除拍卖授权", async function () {
      await auctionNFT.connect(user1).setAuctionApproval(0, auctionContract.address);
      expect(await auctionNFT.isApprovedForAuction(0, auctionContract.address)).to.be.true;
      
      await auctionNFT.connect(user1).burn(0);
      
      // 检查拍卖授权是否被清除（通过检查映射）
      expect(await auctionNFT.auctionApprovals(0)).to.equal(ethers.ZeroAddress);
    });
  });

  describe("拍卖授权功能", function () {
    beforeEach(async function () {
      await auctionNFT.addMinter(minter.address);
      await auctionNFT.connect(minter).mint(user1.address, TOKEN_URI);
    });

    it("所有者应该能够设置拍卖授权", async function () {
      await expect(auctionNFT.connect(user1).setAuctionApproval(0, auctionContract.address))
        .to.emit(auctionNFT, "AuctionApprovalSet")
        .withArgs(0, auctionContract.address);
      
      expect(await auctionNFT.isApprovedForAuction(0, auctionContract.address)).to.be.true;
      expect(await auctionNFT.auctionApprovals(0)).to.equal(auctionContract.address);
    });

    it("所有者应该能够清除拍卖授权", async function () {
      await auctionNFT.connect(user1).setAuctionApproval(0, auctionContract.address);
      
      await expect(auctionNFT.connect(user1).clearAuctionApproval(0))
        .to.emit(auctionNFT, "AuctionApprovalCleared")
        .withArgs(0);
      
      expect(await auctionNFT.isApprovedForAuction(0, auctionContract.address)).to.be.false;
      expect(await auctionNFT.auctionApprovals(0)).to.equal(ethers.ZeroAddress);
    });

    it("非所有者不应该能够设置拍卖授权", async function () {
      await expect(auctionNFT.connect(user2).setAuctionApproval(0, auctionContract.address))
        .to.be.revertedWith("AuctionNFT: only owner can set auction approval");
    });

    it("不应该能够为不存在的代币设置拍卖授权", async function () {
      await expect(auctionNFT.connect(user1).setAuctionApproval(999, auctionContract.address))
        .to.be.revertedWith("AuctionNFT: token does not exist");
    });

    it("转移NFT应该清除拍卖授权", async function () {
      await auctionNFT.connect(user1).setAuctionApproval(0, auctionContract.address);
      expect(await auctionNFT.isApprovedForAuction(0, auctionContract.address)).to.be.true;
      
      await auctionNFT.connect(user1).transferFrom(user1.address, user2.address, 0);
      
      expect(await auctionNFT.isApprovedForAuction(0, auctionContract.address)).to.be.false;
      expect(await auctionNFT.auctionApprovals(0)).to.equal(ethers.ZeroAddress);
    });
  });

  describe("版税功能", function () {
    beforeEach(async function () {
      await auctionNFT.addMinter(minter.address);
      await auctionNFT.connect(minter).mint(user1.address, TOKEN_URI);
    });

    it("所有者应该能够设置代币版税", async function () {
      const recipient = user2.address;
      const percentage = 500; // 5%
      
      await expect(auctionNFT.connect(user1).setTokenRoyalty(0, recipient, percentage))
        .to.emit(auctionNFT, "RoyaltySet")
        .withArgs(0, recipient, percentage);
      
      const [royaltyRecipient, royaltyAmount] = await auctionNFT.royaltyInfo(0, 1000);
      expect(royaltyRecipient).to.equal(recipient);
      expect(royaltyAmount).to.equal(50); // 5% of 1000
    });

    it("合约所有者应该能够设置默认版税", async function () {
      const recipient = user2.address;
      const percentage = 250; // 2.5%
      
      await expect(auctionNFT.setDefaultRoyalty(recipient, percentage))
        .to.emit(auctionNFT, "DefaultRoyaltySet")
        .withArgs(recipient, percentage);
      
      // 对于没有设置特定版税的代币，应该使用默认版税
      const [royaltyRecipient, royaltyAmount] = await auctionNFT.royaltyInfo(0, 1000);
      expect(royaltyRecipient).to.equal(recipient);
      expect(royaltyAmount).to.equal(25); // 2.5% of 1000
    });

    it("不应该能够设置超过最大值的版税", async function () {
      const maxRoyalty = await auctionNFT.MAX_ROYALTY_PERCENTAGE();
      
      await expect(auctionNFT.connect(user1).setTokenRoyalty(0, user2.address, maxRoyalty + 1n))
        .to.be.revertedWith("AuctionNFT: royalty percentage exceeds maximum");
    });

    it("不应该能够设置零地址为版税接收者", async function () {
      await expect(auctionNFT.connect(user1).setTokenRoyalty(0, ethers.ZeroAddress, 500))
        .to.be.revertedWith("AuctionNFT: royalty recipient cannot be zero address");
    });

    it("非所有者不应该能够设置代币版税", async function () {
      await expect(auctionNFT.connect(user2).setTokenRoyalty(0, user2.address, 500))
        .to.be.revertedWith("AuctionNFT: only owner can set royalty");
    });
  });

  describe("接口支持", function () {
    it("应该支持ERC721接口", async function () {
      expect(await auctionNFT.supportsInterface("0x80ac58cd")).to.be.true; // ERC721
    });

    it("应该支持ERC721Metadata接口", async function () {
      expect(await auctionNFT.supportsInterface("0x5b5e139f")).to.be.true; // ERC721Metadata
    });

    // IERC721Mintable接口支持测试已移除
  });

  describe("边界条件测试", function () {
    beforeEach(async function () {
      await auctionNFT.addMinter(minter.address);
    });

    it("应该能够处理长URI", async function () {
      const longURI = "https://example.com/" + "a".repeat(1000);
      await expect(auctionNFT.connect(minter).mint(user1.address, longURI))
        .to.not.be.reverted;
      
      expect(await auctionNFT.tokenURI(0)).to.equal(longURI);
    });

    it("应该能够处理特殊字符URI", async function () {
      const specialURI = "https://example.com/token?id=1&type=special#metadata";
      await expect(auctionNFT.connect(minter).mint(user1.address, specialURI))
        .to.not.be.reverted;
      
      expect(await auctionNFT.tokenURI(0)).to.equal(specialURI);
    });

    it("应该能够处理最大版税百分比", async function () {
      await auctionNFT.connect(minter).mint(user1.address, TOKEN_URI);
      const maxRoyalty = await auctionNFT.MAX_ROYALTY_PERCENTAGE();
      
      await expect(auctionNFT.connect(user1).setTokenRoyalty(0, user2.address, maxRoyalty))
        .to.not.be.reverted;
      
      const [, royaltyAmount] = await auctionNFT.royaltyInfo(0, 10000);
      expect(royaltyAmount).to.equal(1000); // 10% of 10000
    });
  });
});