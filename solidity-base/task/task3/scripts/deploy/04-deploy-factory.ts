import { ethers } from "hardhat";
import { AuctionFactory, AuctionFactoryUpgradeable, ProxyAdmin } from "../../typechain-types";

/**
 * 部署工厂合约脚本
 */
async function deployFactory(priceOracleAddress?: string, auctionHouseTemplateAddress?: string) {
    console.log("\n=== 部署工厂合约 ===");
    
    const [deployer] = await ethers.getSigners();
    console.log("部署账户:", deployer.address);
    console.log("账户余额:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

    // 如果没有提供价格预言机地址，使用默认地址
    if (!priceOracleAddress) {
        console.log("⚠️  未提供价格预言机地址，将使用零地址");
        priceOracleAddress = ethers.ZeroAddress;
    }

    // 部署ProxyAdmin合约
    console.log("\n正在部署ProxyAdmin合约...");
    const ProxyAdminFactory = await ethers.getContractFactory("ProxyAdmin");
    const proxyAdmin: ProxyAdmin = await ProxyAdminFactory.deploy(deployer.address);
    
    await proxyAdmin.waitForDeployment();
    const proxyAdminAddress = await proxyAdmin.getAddress();
    
    console.log("✅ ProxyAdmin部署成功:", proxyAdminAddress);

    // 部署基础AuctionFactory合约
    console.log("\n正在部署AuctionFactory合约...");
    const AuctionFactoryContract = await ethers.getContractFactory("AuctionFactory");
    const auctionFactory: AuctionFactory = await AuctionFactoryContract.deploy(
        deployer.address, // feeRecipient
        priceOracleAddress // priceOracle
    );
    
    await auctionFactory.waitForDeployment();
    const auctionFactoryAddress = await auctionFactory.getAddress();
    
    console.log("✅ AuctionFactory部署成功:", auctionFactoryAddress);

    // 部署可升级AuctionFactoryUpgradeable合约
    console.log("\n正在部署AuctionFactoryUpgradeable合约...");
    const AuctionFactoryUpgradeableContract = await ethers.getContractFactory("AuctionFactoryUpgradeable");
    const auctionFactoryUpgradeable: AuctionFactoryUpgradeable = await AuctionFactoryUpgradeableContract.deploy();
    
    await auctionFactoryUpgradeable.waitForDeployment();
    const auctionFactoryUpgradeableAddress = await auctionFactoryUpgradeable.getAddress();
    
    console.log("✅ AuctionFactoryUpgradeable部署成功:", auctionFactoryUpgradeableAddress);

    // 初始化可升级工厂合约
    console.log("\n正在初始化AuctionFactoryUpgradeable...");
    await auctionFactoryUpgradeable.initialize(
        deployer.address, // feeRecipient
        priceOracleAddress, // priceOracle
        proxyAdminAddress // proxyAdmin
    );
    console.log("✅ AuctionFactoryUpgradeable初始化完成");

    // 如果提供了拍卖模板地址，添加为默认模板
    if (auctionHouseTemplateAddress && auctionHouseTemplateAddress !== ethers.ZeroAddress) {
        console.log("\n正在添加拍卖模板...");
        await auctionFactoryUpgradeable.addTemplate(auctionHouseTemplateAddress, "1.0.0");
        console.log("✅ 拍卖模板添加成功:", auctionHouseTemplateAddress);
    }
    
    // 验证部署
    const factoryOwner = await auctionFactory.owner();
    const factoryConfig = await auctionFactory.globalConfig();
    const upgradeableOwner = await auctionFactoryUpgradeable.owner();
    const upgradeableConfig = await auctionFactoryUpgradeable.globalConfig();
    const totalTemplates = await auctionFactoryUpgradeable.getTotalTemplates();
    
    console.log("\n=== AuctionFactory合约信息 ===");
    console.log("所有者:", factoryOwner);
    console.log("平台手续费率:", factoryConfig.platformFeeRate.toString(), "(基点)");
    console.log("手续费接收者:", factoryConfig.feeRecipient);
    console.log("创建费用:", ethers.formatEther(factoryConfig.creationFee), "ETH");
    
    console.log("\n=== AuctionFactoryUpgradeable合约信息 ===");
    console.log("所有者:", upgradeableOwner);
    console.log("平台手续费率:", upgradeableConfig.platformFeeRate.toString(), "(基点)");
    console.log("手续费接收者:", upgradeableConfig.feeRecipient);
    console.log("创建费用:", ethers.formatEther(upgradeableConfig.creationFee), "ETH");
    console.log("模板数量:", totalTemplates.toString());
    
    // 返回部署信息
    return {
        proxyAdmin: {
            address: proxyAdminAddress,
            owner: deployer.address
        },
        auctionFactory: {
            address: auctionFactoryAddress,
            owner: factoryOwner,
            platformFeeRate: factoryConfig.platformFeeRate.toString(),
            feeRecipient: factoryConfig.feeRecipient,
            creationFee: ethers.formatEther(factoryConfig.creationFee)
        },
        auctionFactoryUpgradeable: {
            address: auctionFactoryUpgradeableAddress,
            owner: upgradeableOwner,
            platformFeeRate: upgradeableConfig.platformFeeRate.toString(),
            feeRecipient: upgradeableConfig.feeRecipient,
            creationFee: ethers.formatEther(upgradeableConfig.creationFee),
            totalTemplates: totalTemplates.toString(),
            initialized: true
        }
    };
}

// 如果直接运行此脚本
if (require.main === module) {
    deployFactory()
        .then((result) => {
            console.log("\n🎉 工厂合约部署完成!");
            console.log(JSON.stringify(result, null, 2));
            process.exit(0);
        })
        .catch((error) => {
            console.error("❌ 部署失败:", error);
            process.exit(1);
        });
}

export { deployFactory };