import { ethers } from "hardhat";
import { AuctionNFT } from "../../typechain-types";

/**
 * 部署NFT合约脚本
 */
async function deployNFT() {
    console.log("\n=== 部署NFT合约 ===");
    
    const [deployer] = await ethers.getSigners();
    console.log("部署账户:", deployer.address);
    console.log("账户余额:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

    // 部署AuctionNFT合约
    console.log("\n正在部署AuctionNFT合约...");
    const AuctionNFTFactory = await ethers.getContractFactory("AuctionNFT");
    const auctionNFT: AuctionNFT = await AuctionNFTFactory.deploy(
        "Auction NFT Collection",
        "ANFT"
    );
    
    await auctionNFT.waitForDeployment();
    const nftAddress = await auctionNFT.getAddress();
    
    console.log("✅ AuctionNFT部署成功:", nftAddress);
    
    // 验证部署
    const name = await auctionNFT.name();
    const symbol = await auctionNFT.symbol();
    const owner = await auctionNFT.owner();
    
    console.log("\n=== 合约信息 ===");
    console.log("名称:", name);
    console.log("符号:", symbol);
    console.log("所有者:", owner);
    
    // 返回部署信息
    return {
        auctionNFT: {
            address: nftAddress,
            name,
            symbol,
            owner
        }
    };
}

// 如果直接运行此脚本
if (require.main === module) {
    deployNFT()
        .then((result) => {
            console.log("\n🎉 NFT合约部署完成!");
            console.log(JSON.stringify(result, null, 2));
            process.exit(0);
        })
        .catch((error) => {
            console.error("❌ 部署失败:", error);
            process.exit(1);
        });
}

export { deployNFT };