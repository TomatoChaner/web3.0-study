const anchor = require('@coral-xyz/anchor');
const { Connection, Keypair, PublicKey } = require('@solana/web3.js');
const fs = require('fs');
const path = require('path');

async function deployProgram() {
    console.log('🚀 开始部署SPL Token Program...');

    try {
        // 设置提供者
        const provider = anchor.AnchorProvider.env();
        anchor.setProvider(provider);

        // 加载程序
        const idl = JSON.parse(fs.readFileSync(
            path.join(__dirname, '../target/idl/spl_token_program.json'), 
            'utf8'
        ));
        
        const programId = new PublicKey(idl.metadata.address);
        const program = new anchor.Program(idl, programId, provider);

        console.log('📋 程序信息:');
        console.log(`   程序ID: ${programId.toString()}`);
        console.log(`   网络: ${provider.connection.rpcEndpoint}`);
        console.log(`   钱包: ${provider.wallet.publicKey.toString()}`);

        // 检查程序是否已部署
        const programAccount = await provider.connection.getAccountInfo(programId);
        if (programAccount) {
            console.log('✅ 程序已成功部署到链上');
        } else {
            console.log('❌ 程序未找到，请先运行 anchor deploy');
            return;
        }

        // 测试程序功能
        console.log('\n🧪 测试程序功能...');
        
        // 创建测试mint
        const mintKeypair = Keypair.generate();
        console.log(`   创建测试mint: ${mintKeypair.publicKey.toString()}`);

        try {
            const tx = await program.methods
                .initializeMint(9) // 9位小数
                .accounts({
                    mint: mintKeypair.publicKey,
                    authority: provider.wallet.publicKey,
                    systemProgram: anchor.web3.SystemProgram.programId,
                    tokenProgram: anchor.utils.token.TOKEN_PROGRAM_ID,
                    rent: anchor.web3.SYSVAR_RENT_PUBKEY,
                })
                .signers([mintKeypair])
                .rpc();

            console.log(`   ✅ 初始化mint成功，交易签名: ${tx}`);
        } catch (error) {
            console.log(`   ⚠️  测试失败: ${error.message}`);
        }

        console.log('\n🎉 部署完成！');
        console.log('\n📝 下一步:');
        console.log('   1. 更新前端应用中的程序ID');
        console.log('   2. 启动本地验证器: solana-test-validator');
        console.log('   3. 运行测试: anchor test');
        console.log('   4. 启动前端应用');

    } catch (error) {
        console.error('❌ 部署失败:', error);
        process.exit(1);
    }
}

// 运行部署
if (require.main === module) {
    deployProgram();
}

module.exports = { deployProgram };