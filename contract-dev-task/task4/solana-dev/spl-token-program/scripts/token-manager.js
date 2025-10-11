const anchor = require('@coral-xyz/anchor');
const { Connection, Keypair, PublicKey, LAMPORTS_PER_SOL } = require('@solana/web3.js');
const { 
    TOKEN_PROGRAM_ID, 
    createMint, 
    getOrCreateAssociatedTokenAccount, 
    mintTo, 
    transfer, 
    burn,
    getMint,
    getAccount
} = require('@solana/spl-token');
const fs = require('fs');

class TokenManager {
    constructor() {
        this.connection = new Connection('http://localhost:8899', 'confirmed');
        this.payer = null;
        this.mint = null;
    }

    async initialize() {
        console.log('🔧 初始化代币管理器...');
        
        // 创建或加载付款人钱包
        try {
            const keypairPath = './keypair.json';
            if (fs.existsSync(keypairPath)) {
                const keypairData = JSON.parse(fs.readFileSync(keypairPath, 'utf8'));
                this.payer = Keypair.fromSecretKey(new Uint8Array(keypairData));
                console.log(`📁 加载现有钱包: ${this.payer.publicKey.toString()}`);
            } else {
                this.payer = Keypair.generate();
                fs.writeFileSync(keypairPath, JSON.stringify(Array.from(this.payer.secretKey)));
                console.log(`🆕 创建新钱包: ${this.payer.publicKey.toString()}`);
            }
        } catch (error) {
            console.error('❌ 钱包初始化失败:', error);
            return false;
        }

        // 检查余额并请求空投
        await this.ensureBalance();
        
        return true;
    }

    async ensureBalance() {
        const balance = await this.connection.getBalance(this.payer.publicKey);
        console.log(`💰 当前余额: ${balance / LAMPORTS_PER_SOL} SOL`);

        if (balance < LAMPORTS_PER_SOL) {
            console.log('💸 余额不足，请求空投...');
            try {
                const signature = await this.connection.requestAirdrop(
                    this.payer.publicKey,
                    2 * LAMPORTS_PER_SOL
                );
                await this.connection.confirmTransaction(signature);
                console.log('✅ 空投成功');
            } catch (error) {
                console.error('❌ 空投失败:', error);
            }
        }
    }

    async createToken(decimals = 9) {
        console.log(`🪙 创建新代币 (${decimals}位小数)...`);
        
        try {
            this.mint = await createMint(
                this.connection,
                this.payer,
                this.payer.publicKey, // mint authority
                this.payer.publicKey, // freeze authority
                decimals
            );

            console.log(`✅ 代币创建成功: ${this.mint.toString()}`);
            
            // 保存mint地址
            fs.writeFileSync('./mint-address.txt', this.mint.toString());
            
            return this.mint;
        } catch (error) {
            console.error('❌ 代币创建失败:', error);
            return null;
        }
    }

    async loadToken(mintAddress) {
        console.log(`📂 加载代币: ${mintAddress}`);
        
        try {
            this.mint = new PublicKey(mintAddress);
            
            // 验证mint是否存在
            const mintInfo = await getMint(this.connection, this.mint);
            console.log(`✅ 代币加载成功`);
            console.log(`   小数位数: ${mintInfo.decimals}`);
            console.log(`   总供应量: ${mintInfo.supply.toString()}`);
            
            return this.mint;
        } catch (error) {
            console.error('❌ 代币加载失败:', error);
            return null;
        }
    }

    async mintTokens(toAddress, amount) {
        if (!this.mint) {
            console.error('❌ 请先创建或加载代币');
            return null;
        }

        console.log(`🏭 铸造 ${amount} 代币到 ${toAddress}...`);

        try {
            const toPublicKey = new PublicKey(toAddress);
            
            // 获取或创建关联代币账户
            const tokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                toPublicKey
            );

            // 获取mint信息以确定小数位数
            const mintInfo = await getMint(this.connection, this.mint);
            const mintAmount = amount * Math.pow(10, mintInfo.decimals);

            // 铸造代币
            const signature = await mintTo(
                this.connection,
                this.payer,
                this.mint,
                tokenAccount.address,
                this.payer,
                mintAmount
            );

            console.log(`✅ 铸造成功，交易签名: ${signature}`);
            return signature;
        } catch (error) {
            console.error('❌ 铸造失败:', error);
            return null;
        }
    }

    async transferTokens(fromAddress, toAddress, amount) {
        if (!this.mint) {
            console.error('❌ 请先创建或加载代币');
            return null;
        }

        console.log(`💸 从 ${fromAddress} 转账 ${amount} 代币到 ${toAddress}...`);

        try {
            const fromPublicKey = new PublicKey(fromAddress);
            const toPublicKey = new PublicKey(toAddress);

            // 获取源账户
            const fromTokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                fromPublicKey
            );

            // 获取目标账户
            const toTokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                toPublicKey
            );

            // 获取mint信息以确定小数位数
            const mintInfo = await getMint(this.connection, this.mint);
            const transferAmount = amount * Math.pow(10, mintInfo.decimals);

            // 转账
            const signature = await transfer(
                this.connection,
                this.payer,
                fromTokenAccount.address,
                toTokenAccount.address,
                fromPublicKey,
                transferAmount
            );

            console.log(`✅ 转账成功，交易签名: ${signature}`);
            return signature;
        } catch (error) {
            console.error('❌ 转账失败:', error);
            return null;
        }
    }

    async burnTokens(ownerAddress, amount) {
        if (!this.mint) {
            console.error('❌ 请先创建或加载代币');
            return null;
        }

        console.log(`🔥 销毁 ${ownerAddress} 的 ${amount} 代币...`);

        try {
            const ownerPublicKey = new PublicKey(ownerAddress);

            // 获取代币账户
            const tokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                ownerPublicKey
            );

            // 获取mint信息以确定小数位数
            const mintInfo = await getMint(this.connection, this.mint);
            const burnAmount = amount * Math.pow(10, mintInfo.decimals);

            // 销毁代币
            const signature = await burn(
                this.connection,
                this.payer,
                tokenAccount.address,
                this.mint,
                ownerPublicKey,
                burnAmount
            );

            console.log(`✅ 销毁成功，交易签名: ${signature}`);
            return signature;
        } catch (error) {
            console.error('❌ 销毁失败:', error);
            return null;
        }
    }

    async getTokenInfo() {
        if (!this.mint) {
            console.error('❌ 请先创建或加载代币');
            return null;
        }

        try {
            const mintInfo = await getMint(this.connection, this.mint);
            
            console.log('📊 代币信息:');
            console.log(`   地址: ${this.mint.toString()}`);
            console.log(`   小数位数: ${mintInfo.decimals}`);
            console.log(`   总供应量: ${Number(mintInfo.supply) / Math.pow(10, mintInfo.decimals)}`);
            console.log(`   铸造权限: ${mintInfo.mintAuthority?.toString() || '无'}`);
            console.log(`   冻结权限: ${mintInfo.freezeAuthority?.toString() || '无'}`);

            return mintInfo;
        } catch (error) {
            console.error('❌ 获取代币信息失败:', error);
            return null;
        }
    }

    async getBalance(ownerAddress) {
        if (!this.mint) {
            console.error('❌ 请先创建或加载代币');
            return null;
        }

        try {
            const ownerPublicKey = new PublicKey(ownerAddress);
            const tokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                ownerPublicKey
            );

            const accountInfo = await getAccount(this.connection, tokenAccount.address);
            const mintInfo = await getMint(this.connection, this.mint);
            
            const balance = Number(accountInfo.amount) / Math.pow(10, mintInfo.decimals);
            console.log(`💰 ${ownerAddress} 的余额: ${balance}`);
            
            return balance;
        } catch (error) {
            console.error('❌ 获取余额失败:', error);
            return null;
        }
    }
}

// 命令行接口
async function main() {
    const args = process.argv.slice(2);
    const command = args[0];

    const manager = new TokenManager();
    await manager.initialize();

    switch (command) {
        case 'create':
            const decimals = parseInt(args[1]) || 9;
            await manager.createToken(decimals);
            break;

        case 'load':
            if (!args[1]) {
                console.error('❌ 请提供mint地址');
                break;
            }
            await manager.loadToken(args[1]);
            break;

        case 'mint':
            if (!args[1] || !args[2]) {
                console.error('❌ 用法: mint <接收地址> <数量>');
                break;
            }
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.mintTokens(args[1], parseFloat(args[2]));
            break;

        case 'transfer':
            if (!args[1] || !args[2] || !args[3]) {
                console.error('❌ 用法: transfer <发送地址> <接收地址> <数量>');
                break;
            }
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.transferTokens(args[1], args[2], parseFloat(args[3]));
            break;

        case 'burn':
            if (!args[1] || !args[2]) {
                console.error('❌ 用法: burn <拥有者地址> <数量>');
                break;
            }
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.burnTokens(args[1], parseFloat(args[2]));
            break;

        case 'info':
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.getTokenInfo();
            break;

        case 'balance':
            if (!args[1]) {
                console.error('❌ 用法: balance <地址>');
                break;
            }
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.getBalance(args[1]);
            break;

        default:
            console.log('📖 SPL代币管理工具');
            console.log('');
            console.log('用法:');
            console.log('  node token-manager.js create [小数位数]     - 创建新代币');
            console.log('  node token-manager.js load <mint地址>      - 加载现有代币');
            console.log('  node token-manager.js mint <地址> <数量>   - 铸造代币');
            console.log('  node token-manager.js transfer <从> <到> <数量> - 转账代币');
            console.log('  node token-manager.js burn <地址> <数量>   - 销毁代币');
            console.log('  node token-manager.js info                 - 查看代币信息');
            console.log('  node token-manager.js balance <地址>       - 查看余额');
            break;
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = TokenManager;