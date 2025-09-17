const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MetaNodeToken", function () {
    let MetaNodeToken;
    let metaNodeToken;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    const TOKEN_NAME = "MetaNode Token";
    const TOKEN_SYMBOL = "MNT";
    const INITIAL_SUPPLY = ethers.parseEther("1000000"); // 1M tokens
    const MAX_SUPPLY = ethers.parseEther("100000000"); // 100M tokens

    beforeEach(async function () {
        // Get the ContractFactory and Signers here
        MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        // Deploy a new contract before each test
        metaNodeToken = await MetaNodeToken.deploy(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
    });

    describe("Deployment", function () {
        it("Should set the right name and symbol", async function () {
            expect(await metaNodeToken.name()).to.equal(TOKEN_NAME);
            expect(await metaNodeToken.symbol()).to.equal(TOKEN_SYMBOL);
        });

        it("Should set the right decimals", async function () {
            expect(await metaNodeToken.decimals()).to.equal(18);
        });

        it("Should assign the initial supply to the owner", async function () {
            const ownerBalance = await metaNodeToken.balanceOf(owner.address);
            expect(await metaNodeToken.totalSupply()).to.equal(ownerBalance);
            expect(ownerBalance).to.equal(INITIAL_SUPPLY);
        });

        it("Should set the correct max supply", async function () {
            expect(await metaNodeToken.MAX_SUPPLY()).to.equal(MAX_SUPPLY);
        });

        it("Should grant DEFAULT_ADMIN_ROLE to owner", async function () {
            const DEFAULT_ADMIN_ROLE = await metaNodeToken.DEFAULT_ADMIN_ROLE();
            expect(await metaNodeToken.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;
        });

        it("Should grant MINTER_ROLE to owner", async function () {
            const MINTER_ROLE = await metaNodeToken.MINTER_ROLE();
            expect(await metaNodeToken.hasRole(MINTER_ROLE, owner.address)).to.be.true;
        });

        it("Should grant PAUSER_ROLE to owner", async function () {
            const PAUSER_ROLE = await metaNodeToken.PAUSER_ROLE();
            expect(await metaNodeToken.hasRole(PAUSER_ROLE, owner.address)).to.be.true;
        });

        it("Should revert if initial supply exceeds max supply", async function () {
            const excessiveSupply = MAX_SUPPLY + 1n;
            await expect(
                MetaNodeToken.deploy(TOKEN_NAME, TOKEN_SYMBOL, excessiveSupply)
            ).to.be.revertedWith("Initial supply exceeds max supply");
        });
    });

    describe("Minting", function () {
        it("Should allow minter to mint tokens", async function () {
            const mintAmount = ethers.parseEther("1000");
            
            await expect(metaNodeToken.mint(addr1.address, mintAmount))
            .to.emit(metaNodeToken, "Transfer")
            .withArgs(ethers.ZeroAddress, addr1.address, mintAmount);

        expect(await metaNodeToken.balanceOf(addr1.address)).to.equal(mintAmount);
            expect(await metaNodeToken.totalSupply()).to.equal(INITIAL_SUPPLY + mintAmount);
        });

        it("Should not allow non-minter to mint tokens", async function () {
            const mintAmount = ethers.parseEther("1000");
            
            await expect(
                metaNodeToken.connect(addr1).mint(addr1.address, mintAmount)
            ).to.be.reverted;
        });

        it("Should not allow minting to zero address", async function () {
            const mintAmount = ethers.parseEther("1000");
            
            await expect(
                metaNodeToken.mint(ethers.ZeroAddress, mintAmount)
            ).to.be.revertedWith("Cannot mint to zero address");
        });

        it("Should not allow minting zero amount", async function () {
            await expect(
                metaNodeToken.mint(addr1.address, 0)
            ).to.be.revertedWith("Amount must be greater than 0");
        });

        it("Should not allow minting beyond max supply", async function () {
            const remainingSupply = await metaNodeToken.remainingMintableSupply();
            const excessAmount = remainingSupply + 1n;
            
            await expect(
                metaNodeToken.mint(addr1.address, excessAmount)
            ).to.be.revertedWith("Minting would exceed max supply");
        });

        it("Should return correct remaining mintable supply", async function () {
            const currentSupply = await metaNodeToken.totalSupply();
            const expectedRemaining = MAX_SUPPLY - currentSupply;
            
            expect(await metaNodeToken.remainingMintableSupply()).to.equal(expectedRemaining);
        });
    });

    describe("Burning", function () {
        beforeEach(async function () {
            // Transfer some tokens to addr1 for burning tests
            await metaNodeToken.transfer(addr1.address, ethers.parseEther("1000"));
        });

        it("Should allow token holder to burn their tokens", async function () {
            const burnAmount = ethers.parseEther("100");
            const initialBalance = await metaNodeToken.balanceOf(addr1.address);
            
            await expect(metaNodeToken.connect(addr1).burn(burnAmount))
                .to.emit(metaNodeToken, "TokensBurned")
                .withArgs(addr1.address, burnAmount);

            expect(await metaNodeToken.balanceOf(addr1.address)).to.equal(
                initialBalance - burnAmount
            );
        });

        it("Should allow burning from another account with allowance", async function () {
            const burnAmount = ethers.parseEther("100");
            
            // Approve addr2 to burn tokens from addr1
            await metaNodeToken.connect(addr1).approve(addr2.address, burnAmount);
            
            await expect(metaNodeToken.connect(addr2).burnFrom(addr1.address, burnAmount))
                .to.emit(metaNodeToken, "TokensBurned")
                .withArgs(addr1.address, burnAmount);
        });

        it("Should not allow burning when paused", async function () {
            await metaNodeToken.pause();
            
            await expect(
                metaNodeToken.connect(addr1).burn(ethers.parseEther("100"))
            ).to.be.revertedWith("Pausable: paused");
        });
    });

    describe("Access Control", function () {
        it("Should allow admin to grant minter role", async function () {
            const MINTER_ROLE = await metaNodeToken.MINTER_ROLE();
            
            await metaNodeToken.grantMinterRole(addr1.address);
            expect(await metaNodeToken.hasRole(MINTER_ROLE, addr1.address)).to.be.true;
        });

        it("Should allow admin to revoke minter role", async function () {
            const MINTER_ROLE = await metaNodeToken.MINTER_ROLE();
            
            await metaNodeToken.grantMinterRole(addr1.address);
            await metaNodeToken.revokeMinterRole(addr1.address);
            
            expect(await metaNodeToken.hasRole(MINTER_ROLE, addr1.address)).to.be.false;
        });

        it("Should not allow non-admin to grant minter role", async function () {
            await expect(
                metaNodeToken.connect(addr1).grantMinterRole(addr2.address)
            ).to.be.reverted;
        });
    });

    describe("Pausable", function () {
        it("Should allow pauser to pause the contract", async function () {
            await metaNodeToken.pause();
            expect(await metaNodeToken.paused()).to.be.true;
        });

        it("Should allow pauser to unpause the contract", async function () {
            await metaNodeToken.pause();
            await metaNodeToken.unpause();
            expect(await metaNodeToken.paused()).to.be.false;
        });

        it("Should not allow non-pauser to pause", async function () {
            await expect(
                metaNodeToken.connect(addr1).pause()
            ).to.be.reverted;
        });

        it("Should not allow transfers when paused", async function () {
            await metaNodeToken.pause();
            
            await expect(
                metaNodeToken.transfer(addr1.address, ethers.parseEther("100"))
            ).to.be.revertedWith("Pausable: paused");
        });

        it("Should not allow minting when paused", async function () {
            await metaNodeToken.pause();
            
            await expect(
                metaNodeToken.mint(addr1.address, ethers.parseEther("100"))
            ).to.be.revertedWith("Pausable: paused");
        });
    });

    describe("ERC20 Functionality", function () {
        it("Should transfer tokens between accounts", async function () {
            const transferAmount = ethers.parseEther("100");
            
            await expect(metaNodeToken.transfer(addr1.address, transferAmount))
                .to.emit(metaNodeToken, "Transfer")
                .withArgs(owner.address, addr1.address, transferAmount);

            expect(await metaNodeToken.balanceOf(addr1.address)).to.equal(transferAmount);
        });

        it("Should handle allowances correctly", async function () {
            const allowanceAmount = ethers.parseEther("100");
            
            await metaNodeToken.approve(addr1.address, allowanceAmount);
            expect(await metaNodeToken.allowance(owner.address, addr1.address)).to.equal(allowanceAmount);
        });

        it("Should transfer from with allowance", async function () {
            const transferAmount = ethers.parseEther("100");
            
            await metaNodeToken.approve(addr1.address, transferAmount);
            await metaNodeToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount);
            
            expect(await metaNodeToken.balanceOf(addr2.address)).to.equal(transferAmount);
        });
    });
});