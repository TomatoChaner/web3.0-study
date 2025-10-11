// SPL Token Program 前端应用
class SPLTokenApp {
    constructor() {
        this.connection = null;
        this.wallet = null;
        this.programId = null;
        this.mintKeypair = null;
        this.mintAddress = null;
        
        this.initializeConnection();
        this.bindEvents();
        this.log('应用初始化完成');
    }

    initializeConnection() {
        // 连接到本地网络
        this.connection = new solanaWeb3.Connection('http://localhost:8899', 'confirmed');
        
        // 从Anchor.toml获取程序ID（这里使用示例ID，实际应用中需要动态获取）
        this.programId = new solanaWeb3.PublicKey('Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS');
        
        this.log('已连接到Solana本地网络');
    }

    bindEvents() {
        document.getElementById('connectWallet').addEventListener('click', () => this.connectWallet());
        document.getElementById('initializeMint').addEventListener('click', () => this.initializeMint());
        document.getElementById('mintTokens').addEventListener('click', () => this.mintTokens());
        document.getElementById('transferTokens').addEventListener('click', () => this.transferTokens());
        document.getElementById('burnTokens').addEventListener('click', () => this.burnTokens());
        document.getElementById('getTokenInfo').addEventListener('click', () => this.getTokenInfo());
    }

    async connectWallet() {
        try {
            // 创建一个新的钱包（在实际应用中，这里会连接到浏览器钱包）
            this.wallet = solanaWeb3.Keypair.generate();
            
            // 请求空投SOL用于测试
            const airdropSignature = await this.connection.requestAirdrop(
                this.wallet.publicKey,
                2 * solanaWeb3.LAMPORTS_PER_SOL
            );
            
            await this.connection.confirmTransaction(airdropSignature);
            
            document.getElementById('walletStatus').textContent = 
                `已连接: ${this.wallet.publicKey.toString().slice(0, 8)}...`;
            
            this.log(`钱包已连接: ${this.wallet.publicKey.toString()}`);
            this.log('已获得2 SOL测试代币');
            
        } catch (error) {
            this.log(`连接钱包失败: ${error.message}`, 'error');
        }
    }

    async initializeMint() {
        if (!this.wallet) {
            this.log('请先连接钱包', 'error');
            return;
        }

        try {
            const decimals = parseInt(document.getElementById('decimals').value);
            
            // 创建新的mint账户
            this.mintKeypair = solanaWeb3.Keypair.generate();
            this.mintAddress = this.mintKeypair.publicKey;
            
            // 计算租金
            const mintRent = await this.connection.getMinimumBalanceForRentExemption(
                splToken.MintLayout.span
            );

            // 创建mint账户的交易
            const transaction = new solanaWeb3.Transaction().add(
                // 创建账户
                solanaWeb3.SystemProgram.createAccount({
                    fromPubkey: this.wallet.publicKey,
                    newAccountPubkey: this.mintAddress,
                    space: splToken.MintLayout.span,
                    lamports: mintRent,
                    programId: splToken.TOKEN_PROGRAM_ID,
                }),
                // 初始化mint
                splToken.createInitializeMintInstruction(
                    this.mintAddress,
                    decimals,
                    this.wallet.publicKey,
                    this.wallet.publicKey
                )
            );

            // 发送交易
            const signature = await solanaWeb3.sendAndConfirmTransaction(
                this.connection,
                transaction,
                [this.wallet, this.mintKeypair]
            );

            document.getElementById('mintAddress').textContent = 
                `Mint地址: ${this.mintAddress.toString()}`;
            document.getElementById('mintAddress').classList.remove('hidden');

            this.log(`代币铸造初始化成功`);
            this.log(`Mint地址: ${this.mintAddress.toString()}`);
            this.log(`交易签名: ${signature}`);

        } catch (error) {
            this.log(`初始化mint失败: ${error.message}`, 'error');
        }
    }

    async mintTokens() {
        if (!this.wallet || !this.mintAddress) {
            this.log('请先连接钱包并初始化mint', 'error');
            return;
        }

        try {
            const toAddress = document.getElementById('mintToAddress').value;
            const amount = parseFloat(document.getElementById('mintAmount').value);

            if (!toAddress || !amount) {
                this.log('请输入有效的地址和数量', 'error');
                return;
            }

            const toPublicKey = new solanaWeb3.PublicKey(toAddress);
            
            // 获取或创建关联代币账户
            const associatedTokenAccount = await splToken.getAssociatedTokenAddress(
                this.mintAddress,
                toPublicKey
            );

            // 检查账户是否存在
            const accountInfo = await this.connection.getAccountInfo(associatedTokenAccount);
            
            const transaction = new solanaWeb3.Transaction();
            
            if (!accountInfo) {
                // 创建关联代币账户
                transaction.add(
                    splToken.createAssociatedTokenAccountInstruction(
                        this.wallet.publicKey,
                        associatedTokenAccount,
                        toPublicKey,
                        this.mintAddress
                    )
                );
            }

            // 铸造代币
            transaction.add(
                splToken.createMintToInstruction(
                    this.mintAddress,
                    associatedTokenAccount,
                    this.wallet.publicKey,
                    amount * Math.pow(10, 9) // 假设9位小数
                )
            );

            const signature = await solanaWeb3.sendAndConfirmTransaction(
                this.connection,
                transaction,
                [this.wallet]
            );

            this.log(`成功铸造 ${amount} 代币到 ${toAddress}`);
            this.log(`交易签名: ${signature}`);

        } catch (error) {
            this.log(`铸造代币失败: ${error.message}`, 'error');
        }
    }

    async transferTokens() {
        if (!this.wallet || !this.mintAddress) {
            this.log('请先连接钱包并初始化mint', 'error');
            return;
        }

        try {
            const toAddress = document.getElementById('transferToAddress').value;
            const amount = parseFloat(document.getElementById('transferAmount').value);

            if (!toAddress || !amount) {
                this.log('请输入有效的地址和数量', 'error');
                return;
            }

            const toPublicKey = new solanaWeb3.PublicKey(toAddress);
            
            // 获取发送方的关联代币账户
            const fromTokenAccount = await splToken.getAssociatedTokenAddress(
                this.mintAddress,
                this.wallet.publicKey
            );

            // 获取接收方的关联代币账户
            const toTokenAccount = await splToken.getAssociatedTokenAddress(
                this.mintAddress,
                toPublicKey
            );

            const transaction = new solanaWeb3.Transaction();

            // 检查接收方账户是否存在，不存在则创建
            const toAccountInfo = await this.connection.getAccountInfo(toTokenAccount);
            if (!toAccountInfo) {
                transaction.add(
                    splToken.createAssociatedTokenAccountInstruction(
                        this.wallet.publicKey,
                        toTokenAccount,
                        toPublicKey,
                        this.mintAddress
                    )
                );
            }

            // 转账
            transaction.add(
                splToken.createTransferInstruction(
                    fromTokenAccount,
                    toTokenAccount,
                    this.wallet.publicKey,
                    amount * Math.pow(10, 9) // 假设9位小数
                )
            );

            const signature = await solanaWeb3.sendAndConfirmTransaction(
                this.connection,
                transaction,
                [this.wallet]
            );

            this.log(`成功转账 ${amount} 代币到 ${toAddress}`);
            this.log(`交易签名: ${signature}`);

        } catch (error) {
            this.log(`转账失败: ${error.message}`, 'error');
        }
    }

    async burnTokens() {
        if (!this.wallet || !this.mintAddress) {
            this.log('请先连接钱包并初始化mint', 'error');
            return;
        }

        try {
            const amount = parseFloat(document.getElementById('burnAmount').value);

            if (!amount) {
                this.log('请输入有效的数量', 'error');
                return;
            }

            // 获取用户的关联代币账户
            const tokenAccount = await splToken.getAssociatedTokenAddress(
                this.mintAddress,
                this.wallet.publicKey
            );

            const transaction = new solanaWeb3.Transaction().add(
                splToken.createBurnInstruction(
                    tokenAccount,
                    this.mintAddress,
                    this.wallet.publicKey,
                    amount * Math.pow(10, 9) // 假设9位小数
                )
            );

            const signature = await solanaWeb3.sendAndConfirmTransaction(
                this.connection,
                transaction,
                [this.wallet]
            );

            this.log(`成功销毁 ${amount} 代币`);
            this.log(`交易签名: ${signature}`);

        } catch (error) {
            this.log(`销毁代币失败: ${error.message}`, 'error');
        }
    }

    async getTokenInfo() {
        if (!this.mintAddress) {
            this.log('请先初始化mint', 'error');
            return;
        }

        try {
            // 获取mint信息
            const mintInfo = await splToken.getMint(this.connection, this.mintAddress);

            document.getElementById('totalSupply').textContent = 
                (Number(mintInfo.supply) / Math.pow(10, mintInfo.decimals)).toFixed(mintInfo.decimals);
            document.getElementById('tokenDecimals').textContent = mintInfo.decimals;
            document.getElementById('mintAuthority').textContent = 
                mintInfo.mintAuthority ? mintInfo.mintAuthority.toString() : '无';
            document.getElementById('freezeAuthority').textContent = 
                mintInfo.freezeAuthority ? mintInfo.freezeAuthority.toString() : '无';

            document.getElementById('tokenInfo').classList.remove('hidden');

            this.log('代币信息获取成功');

        } catch (error) {
            this.log(`获取代币信息失败: ${error.message}`, 'error');
        }
    }

    log(message, type = 'info') {
        const logsContainer = document.getElementById('logs');
        const timestamp = new Date().toLocaleTimeString();
        const logEntry = document.createElement('div');
        
        logEntry.className = type === 'error' ? 'text-red-600' : 'text-gray-800';
        logEntry.textContent = `[${timestamp}] ${message}`;
        
        logsContainer.appendChild(logEntry);
        logsContainer.scrollTop = logsContainer.scrollHeight;
    }
}

// 初始化应用
document.addEventListener('DOMContentLoaded', () => {
    new SPLTokenApp();
});