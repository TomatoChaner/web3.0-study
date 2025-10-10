const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

class TokenInteractor {
    constructor(tokenAddress, signer) {
        this.tokenAddress = tokenAddress;
        this.signer = signer;
        this.token = null;
    }

    async init() {
        const ShibMemeToken = await ethers.getContractFactory("ShibMemeToken");
        this.token = ShibMemeToken.attach(this.tokenAddress).connect(this.signer);
        console.log("已连接到合约:", this.tokenAddress);
    }

    async getBasicInfo() {
        console.log("\n=== 基本信息 ===");
        const name = await this.token.name();
        const symbol = await this.token.symbol();
        const decimals = await this.token.decimals();
        const totalSupply = await this.token.totalSupply();
        const owner = await this.token.owner();

        console.log("代币名称:", name);
        console.log("代币符号:", symbol);
        console.log("小数位数:", decimals);
        console.log("总供应量:", ethers.utils.formatEther(totalSupply));
        console.log("合约所有者:", owner);
    }

    async getTaxInfo() {
        console.log("\n=== 税收信息 ===");
        const buyTax = await this.token.buyTax();
        const sellTax = await this.token.sellTax();
        const maxTxAmount = await this.token.maxTxAmount();
        const maxWalletSize = await this.token.maxWalletSize();

        console.log("买入税:", buyTax.toString(), "%");
        console.log("卖出税:", sellTax.toString(), "%");
        console.log("最大交易额:", ethers.utils.formatEther(maxTxAmount));
        console.log("最大钱包持有量:", ethers.utils.formatEther(maxWalletSize));
    }

    async getWalletInfo() {
        console.log("\n=== 钱包信息 ===");
        const marketingWallet = await this.token.marketingWallet();
        const developmentWallet = await this.token.developmentWallet();
        const liquidityWallet = await this.token.liquidityWallet();

        console.log("营销钱包:", marketingWallet);
        console.log("开发钱包:", developmentWallet);
        console.log("流动性钱包:", liquidityWallet);
    }

    async getAccountInfo(address) {
        console.log(`\n=== 账户信息: ${address} ===`);
        const balance = await this.token.balanceOf(address);
        const isExcludedFromFee = await this.token.isExcludedFromFee(address);
        const isExcludedFromMaxTx = await this.token.isExcludedFromMaxTx(address);
        const isBlacklisted = await this.token.isBlacklisted(address);

        console.log("余额:", ethers.utils.formatEther(balance));
        console.log("免税:", isExcludedFromFee);
        console.log("免最大交易限制:", isExcludedFromMaxTx);
        console.log("黑名单:", isBlacklisted);
    }

    async getContractStatus() {
        console.log("\n=== 合约状态 ===");
        const tradingEnabled = await this.token.tradingEnabled();
        const paused = await this.token.paused();
        const swapEnabled = await this.token.swapEnabled();
        const swapTokensAtAmount = await this.token.swapTokensAtAmount();

        console.log("交易启用:", tradingEnabled);
        console.log("暂停状态:", paused);
        console.log("自动交换启用:", swapEnabled);
        console.log("自动交换阈值:", ethers.utils.formatEther(swapTokensAtAmount));
    }

    // 管理员功能
    async enableTrading() {
        console.log("\n启用交易...");
        const tx = await this.token.enableTrading();
        await tx.wait();
        console.log("交易已启用 ✅");
    }

    async updateBuyTax(newTax) {
        console.log(`\n更新买入税为 ${newTax}%...`);
        const tx = await this.token.updateBuyTax(newTax);
        await tx.wait();
        console.log("买入税已更新 ✅");
    }

    async updateSellTax(newTax) {
        console.log(`\n更新卖出税为 ${newTax}%...`);
        const tx = await this.token.updateSellTax(newTax);
        await tx.wait();
        console.log("卖出税已更新 ✅");
    }

    async updateMaxTxAmount(newAmount) {
        console.log(`\n更新最大交易额为 ${newAmount} ETH...`);
        const amount = ethers.utils.parseEther(newAmount.toString());
        const tx = await this.token.updateMaxTxAmount(amount);
        await tx.wait();
        console.log("最大交易额已更新 ✅");
    }

    async updateMaxWalletSize(newSize) {
        console.log(`\n更新最大钱包持有量为 ${newSize} ETH...`);
        const size = ethers.utils.parseEther(newSize.toString());
        const tx = await this.token.updateMaxWalletSize(size);
        await tx.wait();
        console.log("最大钱包持有量已更新 ✅");
    }

    async excludeFromFee(address, excluded = true) {
        console.log(`\n${excluded ? '排除' : '包含'} ${address} 的费用...`);
        const tx = await this.token.excludeFromFee(address, excluded);
        await tx.wait();
        console.log(`费用${excluded ? '排除' : '包含'}已更新 ✅`);
    }

    async excludeFromMaxTx(address, excluded = true) {
        console.log(`\n${excluded ? '排除' : '包含'} ${address} 的最大交易限制...`);
        const tx = await this.token.excludeFromMaxTx(address, excluded);
        await tx.wait();
        console.log(`最大交易限制${excluded ? '排除' : '包含'}已更新 ✅`);
    }

    async blacklistAddress(address, blacklisted = true) {
        console.log(`\n${blacklisted ? '添加' : '移除'} ${address} ${blacklisted ? '到' : '从'}黑名单...`);
        const tx = await this.token.blacklistAddress(address, blacklisted);
        await tx.wait();
        console.log(`黑名单已${blacklisted ? '添加' : '移除'} ✅`);
    }

    async transfer(to, amount) {
        console.log(`\n转账 ${amount} 代币到 ${to}...`);
        const value = ethers.utils.parseEther(amount.toString());
        const tx = await this.token.transfer(to, value);
        await tx.wait();
        console.log("转账成功 ✅");
    }

    async emergencyWithdrawETH() {
        console.log("\n紧急提取 ETH...");
        const tx = await this.token.emergencyWithdrawETH();
        await tx.wait();
        console.log("ETH 提取成功 ✅");
    }

    async manualSwapAndDistribute() {
        console.log("\n手动交换和分配...");
        const tx = await this.token.manualSwapAndDistribute();
        await tx.wait();
        console.log("手动交换和分配完成 ✅");
    }
}

async function main() {
    const [signer] = await ethers.getSigners();
    console.log("使用账户:", signer.address);

    // 读取部署信息
    const network = await ethers.provider.getNetwork();
    const deploymentFile = path.join(__dirname, "..", "deployments", `${network.name}-${network.chainId}.json`);
    
    if (!fs.existsSync(deploymentFile)) {
        console.error(`未找到部署文件: ${deploymentFile}`);
        console.log("请先运行部署脚本");
        process.exit(1);
    }

    const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
    const tokenAddress = deploymentInfo.contracts.ShibMemeToken.address;

    // 创建交互器
    const interactor = new TokenInteractor(tokenAddress, signer);
    await interactor.init();

    // 获取命令行参数
    const command = process.argv[2];
    const args = process.argv.slice(3);

    switch (command) {
        case "info":
            await interactor.getBasicInfo();
            await interactor.getTaxInfo();
            await interactor.getWalletInfo();
            await interactor.getContractStatus();
            break;

        case "account":
            const address = args[0] || signer.address;
            await interactor.getAccountInfo(address);
            break;

        case "enable-trading":
            await interactor.enableTrading();
            break;

        case "update-buy-tax":
            const buyTax = parseInt(args[0]);
            if (isNaN(buyTax) || buyTax < 0 || buyTax > 25) {
                console.error("请提供有效的买入税 (0-25)");
                process.exit(1);
            }
            await interactor.updateBuyTax(buyTax);
            break;

        case "update-sell-tax":
            const sellTax = parseInt(args[0]);
            if (isNaN(sellTax) || sellTax < 0 || sellTax > 25) {
                console.error("请提供有效的卖出税 (0-25)");
                process.exit(1);
            }
            await interactor.updateSellTax(sellTax);
            break;

        case "exclude-fee":
            const feeAddress = args[0];
            const feeExcluded = args[1] !== "false";
            if (!feeAddress) {
                console.error("请提供地址");
                process.exit(1);
            }
            await interactor.excludeFromFee(feeAddress, feeExcluded);
            break;

        case "blacklist":
            const blacklistAddress = args[0];
            const blacklisted = args[1] !== "false";
            if (!blacklistAddress) {
                console.error("请提供地址");
                process.exit(1);
            }
            await interactor.blacklistAddress(blacklistAddress, blacklisted);
            break;

        case "transfer":
            const toAddress = args[0];
            const amount = parseFloat(args[1]);
            if (!toAddress || isNaN(amount)) {
                console.error("请提供有效的地址和金额");
                process.exit(1);
            }
            await interactor.transfer(toAddress, amount);
            break;

        case "emergency-withdraw":
            await interactor.emergencyWithdrawETH();
            break;

        case "manual-swap":
            await interactor.manualSwapAndDistribute();
            break;

        default:
            console.log("可用命令:");
            console.log("  info                           - 显示合约基本信息");
            console.log("  account [address]              - 显示账户信息");
            console.log("  enable-trading                 - 启用交易");
            console.log("  update-buy-tax <tax>           - 更新买入税 (0-25)");
            console.log("  update-sell-tax <tax>          - 更新卖出税 (0-25)");
            console.log("  exclude-fee <address> [true]   - 排除/包含费用");
            console.log("  blacklist <address> [true]     - 添加/移除黑名单");
            console.log("  transfer <to> <amount>         - 转账代币");
            console.log("  emergency-withdraw             - 紧急提取 ETH");
            console.log("  manual-swap                    - 手动交换和分配");
            console.log("\n示例:");
            console.log("  node scripts/interact.js info");
            console.log("  node scripts/interact.js update-buy-tax 5");
            console.log("  node scripts/interact.js exclude-fee 0x123... true");
            break;
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("交互失败:", error);
        process.exit(1);
    });