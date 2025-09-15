import { ethers } from "hardhat";
import { AuctionHouse, AuctionHouseUpgradeable } from "../../typechain-types";

/**
 * 部署拍卖合约脚本
 */
async function deployAuction(priceOracleAddress?: string) {
    console.log("\n=== 部署拍卖合约 ===");
    
    const [deployer] = await ethers.getSigners();
    console.log("部署账户:", deployer.address);
    console.log("账户余额:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

    // 如果没有提供价格预言机地址，使用默认地址
    if (!priceOracleAddress) {
        console.log("⚠️  未提供价格预言机地址，将使用零地址");
        priceOracleAddress = ethers.ZeroAddress;
    }

    // 部署基础AuctionHouse合约
    console.log("\n正在部署AuctionHouse合约...");
    const AuctionHouseFactory = await ethers.getContractFactory("AuctionHouse");
    const auctionHouse: AuctionHouse = await AuctionHouseFactory.deploy(
        deployer.address, // feeRecipient
        priceOracleAddress // priceOracle
    );
    
    await auctionHouse.waitForDeployment();
    const auctionHouseAddress = await auctionHouse.getAddress();
    
    console.log("✅ AuctionHouse部署成功:", auctionHouseAddress);

    // 部署可升级AuctionHouseUpgradeable合约
    console.log("\n正在部署AuctionHouseUpgradeable合约...");
    const AuctionHouseUpgradeableFactory = await ethers.getContractFactory("AuctionHouseUpgradeable");
    const auctionHouseUpgradeable: AuctionHouseUpgradeable = await AuctionHouseUpgradeableFactory.deploy();
    
    await auctionHouseUpgradeable.waitForDeployment();
    const auctionHouseUpgradeableAddress = await auctionHouseUpgradeable.getAddress();
    
    console.log("✅ AuctionHouseUpgradeable部署成功:", auctionHouseUpgradeableAddress);

    // 初始化可升级合约
    console.log("\n正在初始化AuctionHouseUpgradeable...");
    await auctionHouseUpgradeable.initialize(
        deployer.address, // feeRecipient
        priceOracleAddress // priceOracle
    );
    console.log("✅ AuctionHouseUpgradeable初始化完成");
    
    // 验证部署
    const auctionHouseOwner = await auctionHouse.owner();
    const auctionHouseFeeRecipient = await auctionHouse.feeRecipient();
    const upgradeableOwner = await auctionHouseUpgradeable.owner();
    const upgradeableFeeRecipient = await auctionHouseUpgradeable.feeRecipient();
    
    console.log("\n=== AuctionHouse合约信息 ===");
    console.log("所有者:", auctionHouseOwner);
    console.log("手续费接收者:", auctionHouseFeeRecipient);
    console.log("价格预言机:", priceOracleAddress);
    
    console.log("\n=== AuctionHouseUpgradeable合约信息 ===");
    console.log("所有者:", upgradeableOwner);
    console.log("手续费接收者:", upgradeableFeeRecipient);
    
    // 返回部署信息
    return {
        auctionHouse: {
            address: auctionHouseAddress,
            owner: auctionHouseOwner,
            feeRecipient: auctionHouseFeeRecipient
        },
        auctionHouseUpgradeable: {
            address: auctionHouseUpgradeableAddress,
            owner: upgradeableOwner,
            feeRecipient: upgradeableFeeRecipient,
            initialized: true
        }
    };
}

// 如果直接运行此脚本
if (require.main === module) {
    deployAuction()
        .then((result) => {
            console.log("\n🎉 拍卖合约部署完成!");
            console.log(JSON.stringify(result, null, 2));
            process.exit(0);
        })
        .catch((error) => {
            console.error("❌ 部署失败:", error);
            process.exit(1);
        });
}

export { deployAuction };