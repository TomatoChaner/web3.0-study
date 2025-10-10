const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("Starting deployment...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);
    console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

    // Deploy MetaNode Token (if not already deployed)
    let metaNodeTokenAddress = process.env.METANODE_TOKEN_ADDRESS;
    
    if (!metaNodeTokenAddress) {
        console.log("\nDeploying MetaNode Token...");
        const MetaNodeToken = await ethers.getContractFactory("MockERC20");
        const metaNodeToken = await MetaNodeToken.deploy(
            "MetaNode Token",
            "META",
            ethers.parseEther("1000000") // 1M tokens
        );
        await metaNodeToken.waitForDeployment();
        metaNodeTokenAddress = await metaNodeToken.getAddress();
        console.log("MetaNode Token deployed to:", metaNodeTokenAddress);
    } else {
        console.log("Using existing MetaNode Token at:", metaNodeTokenAddress);
    }

    // Deploy MetaNodeStake contract
    console.log("\nDeploying MetaNodeStake contract...");
    const MetaNodeStake = await ethers.getContractFactory("MetaNodeStake");
    const stakeContract = await MetaNodeStake.deploy();
    await stakeContract.waitForDeployment();
    const stakeContractAddress = await stakeContract.getAddress();
    console.log("MetaNodeStake deployed to:", stakeContractAddress);

    // Initialize the stake contract
    console.log("\nInitializing MetaNodeStake contract...");
    const rewardPerBlock = process.env.REWARD_PER_BLOCK || ethers.parseEther("1"); // 1 META per block
    const initTx = await stakeContract.initialize(
        metaNodeTokenAddress,
        rewardPerBlock,
        deployer.address
    );
    await initTx.wait();
    console.log("MetaNodeStake initialized with reward per block:", ethers.formatEther(rewardPerBlock));

    // Transfer some reward tokens to the stake contract
    if (!process.env.METANODE_TOKEN_ADDRESS) {
        console.log("\nTransferring reward tokens to stake contract...");
        const metaNodeToken = await ethers.getContractAt("MockERC20", metaNodeTokenAddress);
        const rewardAmount = ethers.parseEther("100000"); // 100k tokens for rewards
        const transferTx = await metaNodeToken.transfer(stakeContractAddress, rewardAmount);
        await transferTx.wait();
        console.log("Transferred", ethers.formatEther(rewardAmount), "META tokens to stake contract");
    }

    // Add example pools
    console.log("\nAdding example pools...");

    // ETH Pool
    const ethPoolTx = await stakeContract.addPool(
        "0x0000000000000000000000000000000000000000", // ETH address
        200, // Pool weight
        ethers.parseEther("0.01"), // Min deposit: 0.01 ETH
        100 // Unstake lock: 100 blocks
    );
    await ethPoolTx.wait();
    console.log("Added ETH pool (Pool ID: 0)");

    // If we deployed a test token, add it as a pool too
    if (!process.env.METANODE_TOKEN_ADDRESS) {
        const testTokenPoolTx = await stakeContract.addPool(
            metaNodeTokenAddress,
            100, // Pool weight
            ethers.parseEther("10"), // Min deposit: 10 META
            200 // Unstake lock: 200 blocks
        );
        await testTokenPoolTx.wait();
        console.log("Added META token pool (Pool ID: 1)");
    }

    // Save deployment info
    const deploymentInfo = {
        network: hre.network.name,
        deployer: deployer.address,
        contracts: {
            MetaNodeToken: metaNodeTokenAddress,
            MetaNodeStake: stakeContractAddress
        },
        config: {
            rewardPerBlock: rewardPerBlock.toString(),
            pools: [
                {
                    id: 0,
                    token: "ETH",
                    address: "0x0000000000000000000000000000000000000000",
                    weight: 200,
                    minDeposit: ethers.parseEther("0.01").toString(),
                    lockBlocks: 100
                }
            ]
        },
        timestamp: new Date().toISOString(),
        blockNumber: await ethers.provider.getBlockNumber()
    };

    if (!process.env.METANODE_TOKEN_ADDRESS) {
        deploymentInfo.config.pools.push({
            id: 1,
            token: "META",
            address: metaNodeTokenAddress,
            weight: 100,
            minDeposit: ethers.parseEther("10").toString(),
            lockBlocks: 200
        });
    }

    // Create deployments directory if it doesn't exist
    const deploymentsDir = path.join(__dirname, "..", "deployments");
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir);
    }

    // Save deployment info to file
    const deploymentFile = path.join(deploymentsDir, `${hre.network.name}.json`);
    fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));

    console.log("\n=== Deployment Summary ===");
    console.log("Network:", hre.network.name);
    console.log("MetaNode Token:", metaNodeTokenAddress);
    console.log("MetaNodeStake:", stakeContractAddress);
    console.log("Reward per block:", ethers.formatEther(rewardPerBlock), "META");
    console.log("Deployment info saved to:", deploymentFile);

    // Verify contracts on Etherscan (if on a public network)
    if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
        console.log("\nWaiting before verification...");
        await new Promise(resolve => setTimeout(resolve, 30000)); // Wait 30 seconds

        try {
            console.log("Verifying MetaNodeStake contract...");
            await hre.run("verify:verify", {
                address: stakeContractAddress,
                constructorArguments: []
            });
            console.log("MetaNodeStake contract verified!");
        } catch (error) {
            console.log("Verification failed:", error.message);
        }

        if (!process.env.METANODE_TOKEN_ADDRESS) {
            try {
                console.log("Verifying MetaNode Token contract...");
                await hre.run("verify:verify", {
                    address: metaNodeTokenAddress,
                    constructorArguments: [
                        "MetaNode Token",
                        "META",
                        ethers.parseEther("1000000")
                    ]
                });
                console.log("MetaNode Token contract verified!");
            } catch (error) {
                console.log("Token verification failed:", error.message);
            }
        }
    }

    console.log("\nDeployment completed successfully!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Deployment failed:", error);
        process.exit(1);
    });