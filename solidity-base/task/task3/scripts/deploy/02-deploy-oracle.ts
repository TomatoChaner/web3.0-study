import { ethers } from "hardhat";
import { PriceOracle } from "../../typechain-types";

/**
 * 部署价格预言机合约脚本
 */
async function deployOracle() {
    console.log("\n=== 部署价格预言机合约 ===");
    
    const [deployer] = await ethers.getSigners();
    console.log("部署账户:", deployer.address);
    console.log("账户余额:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

    // 部署PriceOracle合约
    console.log("\n正在部署PriceOracle合约...");
    const PriceOracleFactory = await ethers.getContractFactory("PriceOracle");
    const priceOracle: PriceOracle = await PriceOracleFactory.deploy();
    
    await priceOracle.waitForDeployment();
    const oracleAddress = await priceOracle.getAddress();
    
    console.log("✅ PriceOracle部署成功:", oracleAddress);
    
    // 初始化预言机配置
    console.log("\n正在配置价格预言机...");
    
    // 添加支持的代币
    const supportedTokens = [
        {
            address: ethers.ZeroAddress, // ETH
            symbol: "ETH",
            feedAddress: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419", // ETH/USD Chainlink feed
            heartbeat: 3600, // 1小时
            description: "ETH/USD Price Feed"
        }
    ];
    
    for (const token of supportedTokens) {
        try {
            await priceOracle.addPriceFeed(
                token.address,
                token.feedAddress,
                token.heartbeat,
                token.description
            );
            console.log(`✅ 添加代币支持: ${token.symbol} (${token.address})`);
        } catch (error) {
            console.log(`⚠️  代币 ${token.symbol} 可能已存在`);
        }
    }
    
    // 验证部署
    const owner = await priceOracle.owner();
    const [ethPrice, timestamp] = await priceOracle.getLatestPrice(ethers.ZeroAddress);
    
    console.log("\n=== 合约信息 ===");
    console.log("所有者:", owner);
    console.log("ETH价格:", ethers.formatUnits(ethPrice, 8), "USD");
    console.log("价格时间戳:", new Date(Number(timestamp) * 1000).toLocaleString());
    
    // 返回部署信息
    return {
        priceOracle: {
            address: oracleAddress,
            owner,
            supportedTokens: supportedTokens.length
        }
    };
}

// 如果直接运行此脚本
if (require.main === module) {
    deployOracle()
        .then((result) => {
            console.log("\n🎉 价格预言机部署完成!");
            console.log(JSON.stringify(result, null, 2));
            process.exit(0);
        })
        .catch((error) => {
            console.error("❌ 部署失败:", error);
            process.exit(1);
        });
}

export { deployOracle };