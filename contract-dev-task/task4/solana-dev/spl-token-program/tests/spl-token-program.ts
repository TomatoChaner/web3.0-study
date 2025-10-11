import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { 
  TOKEN_PROGRAM_ID, 
  ASSOCIATED_TOKEN_PROGRAM_ID,
  getAssociatedTokenAddress,
  createAssociatedTokenAccountInstruction,
} from "@solana/spl-token";
import { PublicKey, Keypair, SystemProgram, SYSVAR_RENT_PUBKEY } from "@solana/web3.js";
import { expect } from "chai";

describe("spl-token-program", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.splTokenProgram;
  const provider = anchor.AnchorProvider.env();
  
  // Test accounts
  let mintKeypair: Keypair;
  let tokenMetadataPda: PublicKey;
  let tokenMetadataBump: number;
  let authorityKeypair: Keypair;
  let recipientKeypair: Keypair;
  let authorityTokenAccount: PublicKey;
  let recipientTokenAccount: PublicKey;

  // Token metadata
  const tokenName = "Test Token";
  const tokenSymbol = "TEST";
  const tokenDecimals = 9;
  const mintAmount = 1000000000; // 1 token with 9 decimals

  before(async () => {
    // Generate keypairs
    mintKeypair = Keypair.generate();
    authorityKeypair = Keypair.generate();
    recipientKeypair = Keypair.generate();

    // Derive PDA for token metadata
    [tokenMetadataPda, tokenMetadataBump] = PublicKey.findProgramAddressSync(
      [Buffer.from("metadata"), mintKeypair.publicKey.toBuffer()],
      program.programId
    );

    // Get associated token accounts
    authorityTokenAccount = await getAssociatedTokenAddress(
      mintKeypair.publicKey,
      authorityKeypair.publicKey
    );

    recipientTokenAccount = await getAssociatedTokenAddress(
      mintKeypair.publicKey,
      recipientKeypair.publicKey
    );

    // Airdrop SOL to test accounts
    await provider.connection.confirmTransaction(
      await provider.connection.requestAirdrop(authorityKeypair.publicKey, 2 * anchor.web3.LAMPORTS_PER_SOL)
    );
    
    await provider.connection.confirmTransaction(
      await provider.connection.requestAirdrop(recipientKeypair.publicKey, 2 * anchor.web3.LAMPORTS_PER_SOL)
    );
  });

  it("Initialize mint", async () => {
    const tx = await program.methods
      .initializeMint(tokenDecimals, tokenName, tokenSymbol)
      .accounts({
        mint: mintKeypair.publicKey,
        tokenMetadata: tokenMetadataPda,
        authority: authorityKeypair.publicKey,
        tokenProgram: TOKEN_PROGRAM_ID,
        systemProgram: SystemProgram.programId,
        rent: SYSVAR_RENT_PUBKEY,
      })
      .signers([mintKeypair, authorityKeypair])
      .rpc();

    console.log("Initialize mint transaction signature:", tx);

    // Verify mint account
    const mintAccount = await provider.connection.getAccountInfo(mintKeypair.publicKey);
    expect(mintAccount).to.not.be.null;

    // Verify token metadata
    const tokenMetadata = await program.account.tokenMetadata.fetch(tokenMetadataPda);
    expect(tokenMetadata.name).to.equal(tokenName);
    expect(tokenMetadata.symbol).to.equal(tokenSymbol);
    expect(tokenMetadata.decimals).to.equal(tokenDecimals);
    expect(tokenMetadata.totalSupply.toNumber()).to.equal(0);
    expect(tokenMetadata.authority.toString()).to.equal(authorityKeypair.publicKey.toString());
  });

  it("Create associated token accounts", async () => {
    // Create authority's token account
    const createAuthorityTokenAccountIx = createAssociatedTokenAccountInstruction(
      authorityKeypair.publicKey,
      authorityTokenAccount,
      authorityKeypair.publicKey,
      mintKeypair.publicKey
    );

    // Create recipient's token account
    const createRecipientTokenAccountIx = createAssociatedTokenAccountInstruction(
      recipientKeypair.publicKey,
      recipientTokenAccount,
      recipientKeypair.publicKey,
      mintKeypair.publicKey
    );

    const tx1 = new anchor.web3.Transaction().add(createAuthorityTokenAccountIx);
    await provider.sendAndConfirm(tx1, [authorityKeypair]);

    const tx2 = new anchor.web3.Transaction().add(createRecipientTokenAccountIx);
    await provider.sendAndConfirm(tx2, [recipientKeypair]);

    console.log("Created associated token accounts");
  });

  it("Mint tokens", async () => {
    const tx = await program.methods
      .mintTokens(new anchor.BN(mintAmount))
      .accounts({
        mint: mintKeypair.publicKey,
        tokenMetadata: tokenMetadataPda,
        tokenAccount: authorityTokenAccount,
        recipient: authorityKeypair.publicKey,
        authority: authorityKeypair.publicKey,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([authorityKeypair])
      .rpc();

    console.log("Mint tokens transaction signature:", tx);

    // Verify token account balance
    const tokenAccountInfo = await provider.connection.getTokenAccountBalance(authorityTokenAccount);
    expect(tokenAccountInfo.value.amount).to.equal(mintAmount.toString());

    // Verify total supply updated
    const tokenMetadata = await program.account.tokenMetadata.fetch(tokenMetadataPda);
    expect(tokenMetadata.totalSupply.toNumber()).to.equal(mintAmount);
  });

  it("Transfer tokens", async () => {
    const transferAmount = 500000000; // 0.5 tokens

    const tx = await program.methods
      .transferTokens(new anchor.BN(transferAmount))
      .accounts({
        from: authorityTokenAccount,
        to: recipientTokenAccount,
        mint: mintKeypair.publicKey,
        authority: authorityKeypair.publicKey,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([authorityKeypair])
      .rpc();

    console.log("Transfer tokens transaction signature:", tx);

    // Verify balances
    const fromBalance = await provider.connection.getTokenAccountBalance(authorityTokenAccount);
    const toBalance = await provider.connection.getTokenAccountBalance(recipientTokenAccount);

    expect(fromBalance.value.amount).to.equal((mintAmount - transferAmount).toString());
    expect(toBalance.value.amount).to.equal(transferAmount.toString());
  });

  it("Burn tokens", async () => {
    const burnAmount = 100000000; // 0.1 tokens

    const tx = await program.methods
      .burnTokens(new anchor.BN(burnAmount))
      .accounts({
        mint: mintKeypair.publicKey,
        tokenMetadata: tokenMetadataPda,
        tokenAccount: authorityTokenAccount,
        authority: authorityKeypair.publicKey,
        tokenProgram: TOKEN_PROGRAM_ID,
      })
      .signers([authorityKeypair])
      .rpc();

    console.log("Burn tokens transaction signature:", tx);

    // Verify token account balance
    const tokenAccountInfo = await provider.connection.getTokenAccountBalance(authorityTokenAccount);
    const expectedBalance = mintAmount - 500000000 - burnAmount; // original - transferred - burned
    expect(tokenAccountInfo.value.amount).to.equal(expectedBalance.toString());

    // Verify total supply updated
    const tokenMetadata = await program.account.tokenMetadata.fetch(tokenMetadataPda);
    expect(tokenMetadata.totalSupply.toNumber()).to.equal(mintAmount - burnAmount);
  });

  it("Get token info", async () => {
    const tx = await program.methods
      .getTokenInfo()
      .accounts({
        tokenMetadata: tokenMetadataPda,
        mint: mintKeypair.publicKey,
      })
      .rpc();

    console.log("Get token info transaction signature:", tx);
  });

  it("Update mint authority", async () => {
    const newAuthority = Keypair.generate();

    const tx = await program.methods
      .updateMintAuthority(newAuthority.publicKey)
      .accounts({
        tokenMetadata: tokenMetadataPda,
        mint: mintKeypair.publicKey,
        currentAuthority: authorityKeypair.publicKey,
      })
      .signers([authorityKeypair])
      .rpc();

    console.log("Update mint authority transaction signature:", tx);

    // Verify authority updated
    const tokenMetadata = await program.account.tokenMetadata.fetch(tokenMetadataPda);
    expect(tokenMetadata.authority.toString()).to.equal(newAuthority.publicKey.toString());
  });

  it("Fail to mint with old authority", async () => {
    try {
      await program.methods
        .mintTokens(new anchor.BN(1000000))
        .accounts({
          mint: mintKeypair.publicKey,
          tokenMetadata: tokenMetadataPda,
          tokenAccount: authorityTokenAccount,
          recipient: authorityKeypair.publicKey,
          authority: authorityKeypair.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID,
        })
        .signers([authorityKeypair])
        .rpc();

      // Should not reach here
      expect.fail("Expected transaction to fail");
    } catch (error) {
      expect(error.toString()).to.include("UnauthorizedMintAuthority");
      console.log("Successfully prevented unauthorized minting");
    }
  });
});
