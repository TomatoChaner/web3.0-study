const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    const network = await ethers.provider.getNetwork();
    console.log("当前网络:", network.name, "Chain ID:", network.chainId);

    // 读取部署信息
    const deploymentFile = path.join(__dirname, "..", "deployments", `${network.name}-${network.chainId}.json`);
    
    if (!fs.existsSync(deploymentFile)) {
        console.error(`未找到部署文件: ${deploymentFile}`);
        console.log("请先运行部署脚本");
        process.exit(1);
    }

    const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
    const tokenAddress = deploymentInfo.contracts.ShibMemeToken.address;
    const constructorArgs = deploymentInfo.contracts.ShibMemeToken.constructorArgs;

    console.log("验证合约地址:", tokenAddress);
    console.log("构造函数参数:", constructorArgs);

    try {
        // 验证合约
        await hre.run("verify:verify", {
            address: tokenAddress,
            constructorArguments: constructorArgs,
        });

        console.log("合约验证成功! ✅");
    } catch (error) {
        if (error.message.includes("Already Verified")) {
            console.log("合约已经验证过了 ✅");
        } else {
            console.error("验证失败:", error.message);
            process.exit(1);
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("验证过程出错:", error);
        process.exit(1);
    });