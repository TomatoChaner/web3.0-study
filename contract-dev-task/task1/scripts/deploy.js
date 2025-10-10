const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("开始部署 SHIB Meme Token 合约...");

    // 获取部署者账户
    const [deployer] = await ethers.getSigners();
    console.log("部署者地址:", deployer.address);
    console.log("部署者余额:", ethers.utils.formatEther(await deployer.getBalance()), "ETH");

    // 从环境变量获取配置
    const marketingWallet = process.env.MARKETING_WALLET || deployer.address;
    const developmentWallet = process.env.DEVELOPMENT_WALLET || deployer.address;
    const liquidityWallet = process.env.LIQUIDITY_WALLET || deployer.address;
    
    // 网络配置
    const network = await ethers.provider.getNetwork();
    console.log("部署网络:", network.name, "Chain ID:", network.chainId);

    // Uniswap V2 Router 地址 (根据网络设置)
    let uniswapV2RouterAddress;
    switch (network.chainId) {
        case 1: // Ethereum Mainnet
            uniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
            break;
        case 5: // Goerli Testnet
            uniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
            break;
        case 11155111: // Sepolia Testnet
            uniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
            break;
        case 56: // BSC Mainnet
            uniswapV2RouterAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
            break;
        case 97: // BSC Testnet
            uniswapV2RouterAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
            break;
        case 31337: // Hardhat Network
            // 在本地网络部署模拟的 Uniswap 合约
            console.log("检测到本地网络，部署模拟 Uniswap 合约...");
            
            // 部署 WETH
            const WETH = await ethers.getContractFactory("contracts/mocks/WETH9.sol:WETH9");
            const weth = await WETH.deploy();
            await weth.deployed();
            console.log("WETH 部署地址:", weth.address);

            // 部署 Uniswap V2 Factory
            const UniswapV2Factory = await ethers.getContractFactory("contracts/mocks/UniswapV2Factory.sol:UniswapV2Factory");
            const factory = await UniswapV2Factory.deploy(deployer.address);
            await factory.deployed();
            console.log("Uniswap V2 Factory 部署地址:", factory.address);

            // 部署 Uniswap V2 Router
            const UniswapV2Router = await ethers.getContractFactory("contracts/mocks/UniswapV2Router02.sol:UniswapV2Router02");
            const router = await UniswapV2Router.deploy(factory.address, weth.address);
            await router.deployed();
            console.log("Uniswap V2 Router 部署地址:", router.address);
            
            uniswapV2RouterAddress = router.address;
            break;
        default:
            throw new Error(`不支持的网络 Chain ID: ${network.chainId}`);
    }

    console.log("使用 Uniswap V2 Router 地址:", uniswapV2RouterAddress);

    // 部署 ShibMemeToken 合约
    console.log("\n部署 ShibMemeToken 合约...");
    const ShibMemeToken = await ethers.getContractFactory("ShibMemeToken");
    
    const token = await ShibMemeToken.deploy(
        marketingWallet,
        developmentWallet,
        liquidityWallet,
        uniswapV2RouterAddress
    );

    await token.deployed();
    console.log("ShibMemeToken 部署地址:", token.address);

    // 获取交易对地址
    const pairAddress = await token.uniswapV2Pair();
    console.log("Uniswap V2 交易对地址:", pairAddress);

    // 验证部署
    console.log("\n验证合约部署...");
    const name = await token.name();
    const symbol = await token.symbol();
    const totalSupply = await token.totalSupply();
    const owner = await token.owner();

    console.log("代币名称:", name);
    console.log("代币符号:", symbol);
    console.log("总供应量:", ethers.utils.formatEther(totalSupply));
    console.log("合约所有者:", owner);
    console.log("营销钱包:", await token.marketingWallet());
    console.log("开发钱包:", await token.developmentWallet());
    console.log("流动性钱包:", await token.liquidityWallet());

    // 保存部署信息
    const deploymentInfo = {
        network: network.name,
        chainId: network.chainId,
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
        contracts: {
            ShibMemeToken: {
                address: token.address,
                constructorArgs: [
                    marketingWallet,
                    developmentWallet,
                    liquidityWallet,
                    uniswapV2RouterAddress
                ]
            },
            UniswapV2Pair: {
                address: pairAddress
            }
        },
        wallets: {
            marketing: marketingWallet,
            development: developmentWallet,
            liquidity: liquidityWallet
        }
    };

    // 创建部署目录
    const deploymentsDir = path.join(__dirname, "..", "deployments");
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir, { recursive: true });
    }

    // 保存部署信息到文件
    const deploymentFile = path.join(deploymentsDir, `${network.name}-${network.chainId}.json`);
    fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
    console.log(`\n部署信息已保存到: ${deploymentFile}`);

    // 如果在测试网或主网，提示验证合约
    if (network.chainId !== 31337) {
        console.log("\n请使用以下命令验证合约:");
        console.log(`npx hardhat verify --network ${network.name} ${token.address} "${marketingWallet}" "${developmentWallet}" "${liquidityWallet}" "${uniswapV2RouterAddress}"`);
    }

    console.log("\n部署完成! 🎉");
    
    return {
        token,
        deploymentInfo
    };
}

// 如果直接运行此脚本
if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error("部署失败:", error);
            process.exit(1);
        });
}

module.exports = main;