const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Simple Contract Test", function () {
    let metaNodeToken;
    let stakeContract;
    let owner;
    let addr1;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();

        // Deploy MetaNodeToken
        const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
        metaNodeToken = await MetaNodeToken.deploy(
            "MetaNode Token",
            "MNT", 
            ethers.parseEther("1000000")
        );

        // Deploy StakeContract
        const StakeContract = await ethers.getContractFactory("StakeContract");
        stakeContract = await StakeContract.deploy(metaNodeToken.target);

        // Grant minter role
        await metaNodeToken.grantMinterRole(stakeContract.target);
    });

    it("Should deploy contracts successfully", async function () {
        expect(await metaNodeToken.name()).to.equal("MetaNode Token");
        expect(await metaNodeToken.symbol()).to.equal("MNT");
        expect(await stakeContract.rewardToken()).to.equal(metaNodeToken.target);
    });

    it("Should allow staking", async function () {
        const stakeAmount = ethers.parseEther("1.0");
        
        await expect(stakeContract.connect(addr1).stake({ value: stakeAmount }))
            .to.emit(stakeContract, "Staked");

        const stakeInfo = await stakeContract.getUserStakeInfo(addr1.address);
        expect(stakeInfo.amount).to.equal(stakeAmount);
        expect(stakeInfo.active).to.be.true;
    });

    it("Should track total staked amount", async function () {
        const stakeAmount = ethers.parseEther("2.0");
        
        await stakeContract.connect(addr1).stake({ value: stakeAmount });
        
        expect(await stakeContract.totalStaked()).to.equal(stakeAmount);
    });
});