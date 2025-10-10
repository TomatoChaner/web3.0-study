const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("开始添加流动性...");

    const [deployer] = await ethers.getSigners();
    console.log("操作者地址:", deployer.address);
    console.log("操作者余额:", ethers.utils.formatEther(await deployer.getBalance()), "ETH");

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

    // 连接到合约
    const ShibMemeToken = await ethers.getContractFactory("ShibMemeToken");
    const token = ShibMemeToken.attach(tokenAddress);

    // 获取 Uniswap Router
    const routerAddress = await token.uniswapV2Router();
    const IUniswapV2Router = await ethers.getContractAt("IUniswapV2Router02", routerAddress);

    // 从环境变量或命令行参数获取配置
    const tokenAmount = process.env.LIQUIDITY_TOKEN_AMOUNT || process.argv[2] || "1000000"; // 默认 100万代币
    const ethAmount = process.env.LIQUIDITY_ETH_AMOUNT || process.argv[3] || "10"; // 默认 10 ETH

    const tokenAmountWei = ethers.utils.parseEther(tokenAmount);
    const ethAmountWei = ethers.utils.parseEther(ethAmount);

    console.log("代币数量:", ethers.utils.formatEther(tokenAmountWei));
    console.log("ETH 数量:", ethers.utils.formatEther(ethAmountWei));

    // 检查代币余额
    const tokenBalance = await token.balanceOf(deployer.address);
    if (tokenBalance.lt(tokenAmountWei)) {
        console.error("代币余额不足!");
        console.log("当前余额:", ethers.utils.formatEther(tokenBalance));
        console.log("需要余额:", ethers.utils.formatEther(tokenAmountWei));
        process.exit(1);
    }

    // 检查 ETH 余额
    const ethBalance = await deployer.getBalance();
    if (ethBalance.lt(ethAmountWei.add(ethers.utils.parseEther("0.1")))) { // 预留 0.1 ETH 作为 gas
        console.error("ETH 余额不足!");
        console.log("当前余额:", ethers.utils.formatEther(ethBalance));
        console.log("需要余额:", ethers.utils.formatEther(ethAmountWei.add(ethers.utils.parseEther("0.1"))));
        process.exit(1);
    }

    // 检查交易是否已启用
    const tradingEnabled = await token.tradingEnabled();
    if (!tradingEnabled) {
        console.log("交易未启用，正在启用交易...");
        const enableTx = await token.enableTrading();
        await enableTx.wait();
        console.log("交易已启用 ✅");
    }

    // 授权代币给 Router
    console.log("\n授权代币给 Uniswap Router...");
    const allowance = await token.allowance(deployer.address, routerAddress);
    if (allowance.lt(tokenAmountWei)) {
        const approveTx = await token.approve(routerAddress, tokenAmountWei);
        await approveTx.wait();
        console.log("代币授权成功 ✅");
    } else {
        console.log("代币已授权 ✅");
    }

    // 添加流动性
    console.log("\n添加流动性到 Uniswap...");
    const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20分钟后过期

    try {
        const addLiquidityTx = await IUniswapV2Router.addLiquidityETH(
            tokenAddress,
            tokenAmountWei,
            0, // 最小代币数量 (设为0以避免滑点问题)
            0, // 最小 ETH 数量 (设为0以避免滑点问题)
            deployer.address, // LP 代币接收者
            deadline,
            {
                value: ethAmountWei,
                gasLimit: 500000 // 设置较高的 gas limit
            }
        );

        console.log("交易哈希:", addLiquidityTx.hash);
        const receipt = await addLiquidityTx.wait();
        console.log("流动性添加成功! ✅");
        console.log("Gas 使用量:", receipt.gasUsed.toString());

        // 获取交易对地址和 LP 代币余额
        const pairAddress = await token.uniswapV2Pair();
        const IUniswapV2Pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress);
        const lpBalance = await IUniswapV2Pair.balanceOf(deployer.address);
        
        console.log("\n流动性信息:");
        console.log("交易对地址:", pairAddress);
        console.log("LP 代币余额:", ethers.utils.formatEther(lpBalance));

        // 获取储备金信息
        const reserves = await IUniswapV2Pair.getReserves();
        const token0 = await IUniswapV2Pair.token0();
        const token1 = await IUniswapV2Pair.token1();
        
        console.log("\n储备金信息:");
        if (token0.toLowerCase() === tokenAddress.toLowerCase()) {
            console.log("代币储备:", ethers.utils.formatEther(reserves[0]));
            console.log("ETH 储备:", ethers.utils.formatEther(reserves[1]));
        } else {
            console.log("ETH 储备:", ethers.utils.formatEther(reserves[0]));
            console.log("代币储备:", ethers.utils.formatEther(reserves[1]));
        }

        // 更新部署信息
        deploymentInfo.liquidity = {
            added: true,
            timestamp: new Date().toISOString(),
            tokenAmount: ethers.utils.formatEther(tokenAmountWei),
            ethAmount: ethers.utils.formatEther(ethAmountWei),
            lpTokens: ethers.utils.formatEther(lpBalance),
            transactionHash: addLiquidityTx.hash
        };

        fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
        console.log(`\n流动性信息已更新到: ${deploymentFile}`);

    } catch (error) {
        console.error("添加流动性失败:", error.message);
        
        // 如果是 gas 估算失败，提供更多信息
        if (error.message.includes("gas")) {
            console.log("\n可能的解决方案:");
            console.log("1. 确保交易已启用");
            console.log("2. 检查代币和 ETH 余额");
            console.log("3. 增加 gas limit");
            console.log("4. 检查网络拥堵情况");
        }
        
        process.exit(1);
    }

    console.log("\n流动性添加完成! 🎉");
    console.log("现在可以在 Uniswap 上交易代币了!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("添加流动性过程出错:", error);
        process.exit(1);
    });