const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🧪 Testing Sepolia deployment...");
  
  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("📝 Testing with account:", deployer.address);
  
  // 获取账户余额
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(balance), "ETH");
  
  // 读取部署信息
  const deploymentPath = "./deployments/sepolia-deployment.json";
  if (!fs.existsSync(deploymentPath)) {
    throw new Error("❌ Deployment file not found. Please deploy contracts first.");
  }
  
  const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  console.log("📋 Contract Addresses:");
  console.log("   MetaNodeToken:", deployment.contracts.MetaNodeToken.address);
  console.log("   StakeContract:", deployment.contracts.StakeContract.address);
  
  // 获取合约实例
  const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
  const StakeContract = await ethers.getContractFactory("StakeContract");
  
  const metaNodeToken = MetaNodeToken.attach(deployment.contracts.MetaNodeToken.address);
  const stakeContract = StakeContract.attach(deployment.contracts.StakeContract.address);
  
  console.log("\n🔍 Testing contract functions...");
  
  // 测试代币合约
  console.log("\n📊 MetaNodeToken Tests:");
  const tokenName = await metaNodeToken.name();
  const tokenSymbol = await metaNodeToken.symbol();
  const totalSupply = await metaNodeToken.totalSupply();
  const maxSupply = await metaNodeToken.MAX_SUPPLY();
  const deployerBalance = await metaNodeToken.balanceOf(deployer.address);
  
  console.log("   Name:", tokenName);
  console.log("   Symbol:", tokenSymbol);
  console.log("   Total Supply:", ethers.formatEther(totalSupply), "MNT");
  console.log("   Max Supply:", ethers.formatEther(maxSupply), "MNT");
  console.log("   Deployer Balance:", ethers.formatEther(deployerBalance), "MNT");
  
  // 测试质押合约
  console.log("\n🏦 StakeContract Tests:");
  const totalStaked = await stakeContract.totalStaked();
  const totalRewardsDistributed = await stakeContract.totalRewardsDistributed();
  const rewardToken = await stakeContract.rewardToken();
  
  console.log("   Total Staked:", ethers.formatEther(totalStaked), "ETH");
  console.log("   Total Rewards Distributed:", ethers.formatEther(totalRewardsDistributed), "MNT");
  console.log("   Reward Token:", rewardToken);
  console.log("   Reward Token matches MetaNodeToken:", rewardToken.toLowerCase() === deployment.contracts.MetaNodeToken.address.toLowerCase());
  
  // 检查权限
  console.log("\n🔑 Permission Tests:");
  const MINTER_ROLE = await metaNodeToken.MINTER_ROLE();
  const hasRole = await metaNodeToken.hasRole(MINTER_ROLE, deployment.contracts.StakeContract.address);
  console.log("   MINTER_ROLE:", MINTER_ROLE);
  console.log("   StakeContract has MINTER_ROLE:", hasRole);
  
  // 检查合约常量
  console.log("\n⚙️ Contract Constants:");
  const minStakeAmount = await stakeContract.MIN_STAKE_AMOUNT();
  const maxStakeAmount = await stakeContract.MAX_STAKE_AMOUNT();
  const rewardRate = await stakeContract.REWARD_RATE();
  
  console.log("   Min Stake Amount:", ethers.formatEther(minStakeAmount), "ETH");
  console.log("   Max Stake Amount:", ethers.formatEther(maxStakeAmount), "ETH");
  console.log("   Reward Rate:", rewardRate.toString(), "basis points (per day)");
  
  // 检查用户质押信息
  console.log("\n👤 User Stake Information:");
  const userStake = await stakeContract.stakes(deployer.address);
  const userTotalStaked = await stakeContract.userTotalStaked(deployer.address);
  
  console.log("   User Total Staked:", ethers.formatEther(userTotalStaked), "ETH");
  console.log("   Current Stake Active:", userStake.active);
  if (userStake.active) {
    console.log("   Stake Amount:", ethers.formatEther(userStake.amount), "ETH");
    console.log("   Start Time:", new Date(Number(userStake.startTime) * 1000).toISOString());
    console.log("   Accumulated Rewards:", ethers.formatEther(userStake.accumulatedRewards), "MNT");
  }
  
  console.log("\n✅ All tests completed successfully!");
  console.log("\n📝 Next steps:");
  console.log("   1. 前端已配置连接到Sepolia合约");
  console.log("   2. 可以通过前端界面测试质押功能");
  console.log("   3. 确保钱包连接到Sepolia测试网");
  console.log("   4. 需要一些测试代币来测试质押功能");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Test failed:", error);
    process.exit(1);
  });