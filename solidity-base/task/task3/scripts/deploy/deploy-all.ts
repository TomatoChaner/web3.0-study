import { ethers } from "hardhat";
import { deployNFT } from "./01-deploy-nft";
import { deployOracle } from "./02-deploy-oracle";
import { deployAuction } from "./03-deploy-auction";
import { deployFactory } from "./04-deploy-factory";

/**
 * 完整部署脚本 - 按顺序部署所有合约
 */
async function deployAll() {
    console.log("🚀 开始完整部署流程...");
    console.log("=".repeat(50));
    
    const [deployer] = await ethers.getSigners();
    console.log("部署账户:", deployer.address);
    console.log("初始余额:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");
    
    const deploymentResults: any = {};
    
    try {
        // 第一步：部署NFT合约
        console.log("\n📦 第1步：部署NFT合约");
        const nftResult = await deployNFT();
        deploymentResults.nft = nftResult;
        
        // 第二步：部署价格预言机
        console.log("\n🔮 第2步：部署价格预言机");
        const oracleResult = await deployOracle();
        deploymentResults.oracle = oracleResult;
        
        // 第三步：部署拍卖合约
        console.log("\n🏛️ 第3步：部署拍卖合约");
        const auctionResult = await deployAuction(oracleResult.priceOracle.address);
        deploymentResults.auction = auctionResult;
        
        // 第四步：部署工厂合约
        console.log("\n🏭 第4步：部署工厂合约");
        const factoryResult = await deployFactory(
            oracleResult.priceOracle.address,
            auctionResult.auctionHouseUpgradeable.address
        );
        deploymentResults.factory = factoryResult;
        
        // 显示最终余额
        const finalBalance = await deployer.provider.getBalance(deployer.address);
        // 注意：deploymentCost 可能不存在于返回结果中，这里仅作为示例
        // 实际的gas消耗可以通过交易回执获取
        
        console.log("\n💰 部署成本统计");
        console.log("=".repeat(30));
        console.log("最终余额:", ethers.formatEther(finalBalance), "ETH");
        
        // 生成部署摘要
        console.log("\n📋 部署摘要");
        console.log("=".repeat(30));
        console.log("NFT合约:", deploymentResults.nft.address);
        console.log("价格预言机:", deploymentResults.oracle.priceOracle.address);
        console.log("拍卖合约:", deploymentResults.auction.auctionHouse.address);
        console.log("可升级拍卖合约:", deploymentResults.auction.auctionHouseUpgradeable.address);
        console.log("工厂合约:", deploymentResults.factory.auctionFactory.address);
        console.log("可升级工厂合约:", deploymentResults.factory.auctionFactoryUpgradeable.address);
        console.log("代理管理合约:", deploymentResults.factory.proxyAdmin.address);
        
        // 保存部署结果到文件
        const fs = require('fs');
        const path = require('path');
        const deploymentFile = path.join(__dirname, '../../deployments.json');
        
        const network = await ethers.provider.getNetwork();
        const deploymentData = {
            network: network.name,
            chainId: network.chainId.toString(),
            deployer: deployer.address,
            timestamp: new Date().toISOString(),
            contracts: {
                AuctionNFT: deploymentResults.nft.address,
                PriceOracle: deploymentResults.oracle.priceOracle.address,
                AuctionHouse: deploymentResults.auction.auctionHouse.address,
                AuctionHouseUpgradeable: deploymentResults.auction.auctionHouseUpgradeable.address,
                AuctionFactory: deploymentResults.factory.auctionFactory.address,
                AuctionFactoryUpgradeable: deploymentResults.factory.auctionFactoryUpgradeable.address,
                ProxyAdmin: deploymentResults.factory.proxyAdmin.address
            },
            gasUsed: "0.0"
        };
        
        fs.writeFileSync(deploymentFile, JSON.stringify(deploymentData, null, 2));
        console.log("\n💾 部署信息已保存到:", deploymentFile);
        
        console.log("\n🎉 所有合约部署完成!");
        return deploymentResults;
        
    } catch (error) {
        console.error("\n❌ 部署过程中发生错误:", error);
        
        // 显示已部署的合约（如果有）
        if (Object.keys(deploymentResults).length > 0) {
            console.log("\n⚠️  已部署的合约:");
            Object.entries(deploymentResults).forEach(([key, value]: [string, any]) => {
                if (value && value.address) {
                    console.log(`${key}:`, value.address);
                }
            });
        }
        
        throw error;
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    deployAll()
        .then(() => {
            console.log("\n✨ 部署流程完成!");
            process.exit(0);
        })
        .catch((error) => {
            console.error("❌ 部署失败:", error);
            process.exit(1);
        });
}

export { deployAll };