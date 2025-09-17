const { ethers } = require('ethers');
const SupabaseService = require('./supabase');
require('dotenv').config();

class EventListener {
    constructor() {
        this.provider = new ethers.JsonRpcProvider(process.env.RPC_URL || 'http://127.0.0.1:8545');
        this.supabaseService = new SupabaseService();
        this.stakeContract = null;
        this.tokenContract = null;
        this.isListening = false;
        this.lastProcessedBlock = 0;
    }

    async initialize() {
        try {
            // 读取部署信息
            const fs = require('fs');
            const deploymentPath = './deployments/localhost-deployment.json';
            
            if (!fs.existsSync(deploymentPath)) {
                throw new Error('Deployment file not found. Please deploy contracts first.');
            }

            const deployment = JSON.parse(fs.readFileSync(deploymentPath, 'utf8'));
            
            // 加载合约ABI
            const StakeContractABI = require('../artifacts/contracts/StakeContract.sol/StakeContract.json').abi;
            const MetaNodeTokenABI = require('../artifacts/contracts/MetaNodeToken.sol/MetaNodeToken.json').abi;

            // 创建合约实例
            this.stakeContract = new ethers.Contract(
                deployment.contracts.StakeContract.address,
                StakeContractABI,
                this.provider
            );

            this.tokenContract = new ethers.Contract(
                deployment.contracts.MetaNodeToken.address,
                MetaNodeTokenABI,
                this.provider
            );

            // 获取最后处理的区块号
            await this.loadLastProcessedBlock();

            console.log('✅ Event listener initialized successfully');
            console.log(`📍 Stake Contract: ${deployment.contracts.StakeContract.address}`);
            console.log(`🪙 Token Contract: ${deployment.contracts.MetaNodeToken.address}`);
            console.log(`📦 Starting from block: ${this.lastProcessedBlock}`);

        } catch (error) {
            console.error('❌ Failed to initialize event listener:', error);
            throw error;
        }
    }

    async loadLastProcessedBlock() {
        try {
            // 从数据库获取最后处理的区块号
            const { data } = await this.supabaseService.supabase
                .from('system_config')
                .select('value')
                .eq('key', 'last_processed_block')
                .single();

            if (data && data.value) {
                this.lastProcessedBlock = parseInt(data.value);
            } else {
                // 如果没有记录，从当前区块开始
                this.lastProcessedBlock = await this.provider.getBlockNumber();
                await this.saveLastProcessedBlock(this.lastProcessedBlock);
            }
        } catch (error) {
            console.error('Error loading last processed block:', error);
            this.lastProcessedBlock = await this.provider.getBlockNumber();
        }
    }

    async saveLastProcessedBlock(blockNumber) {
        try {
            await this.supabaseService.supabase
                .from('system_config')
                .upsert([{
                    key: 'last_processed_block',
                    value: blockNumber.toString(),
                    description: 'Last processed block number for event listener'
                }]);
        } catch (error) {
            console.error('Error saving last processed block:', error);
        }
    }

    async startListening() {
        if (this.isListening) {
            console.log('⚠️ Event listener is already running');
            return;
        }

        this.isListening = true;
        console.log('🎧 Starting event listener...');

        try {
            // 处理历史事件
            await this.processHistoricalEvents();

            // 监听新事件
            this.setupEventListeners();

            // 定期检查遗漏的事件
            this.startPeriodicCheck();

            console.log('✅ Event listener started successfully');
        } catch (error) {
            console.error('❌ Failed to start event listener:', error);
            this.isListening = false;
            throw error;
        }
    }

    async processHistoricalEvents() {
        console.log('📚 Processing historical events...');
        
        const currentBlock = await this.provider.getBlockNumber();
        const fromBlock = this.lastProcessedBlock;
        const batchSize = 1000; // 批量处理区块

        for (let startBlock = fromBlock; startBlock <= currentBlock; startBlock += batchSize) {
            const endBlock = Math.min(startBlock + batchSize - 1, currentBlock);
            
            console.log(`📦 Processing blocks ${startBlock} to ${endBlock}`);
            
            try {
                await this.processBlockRange(startBlock, endBlock);
                await this.saveLastProcessedBlock(endBlock);
                this.lastProcessedBlock = endBlock;
            } catch (error) {
                console.error(`Error processing blocks ${startBlock}-${endBlock}:`, error);
                // 继续处理下一批，但记录错误
            }
        }

        console.log('✅ Historical events processed');
    }

    async processBlockRange(fromBlock, toBlock) {
        // 获取质押合约事件
        const stakeEvents = await this.stakeContract.queryFilter('*', fromBlock, toBlock);
        
        // 获取代币合约事件
        const tokenEvents = await this.tokenContract.queryFilter('*', fromBlock, toBlock);

        // 处理所有事件
        const allEvents = [...stakeEvents, ...tokenEvents].sort((a, b) => {
            if (a.blockNumber !== b.blockNumber) {
                return a.blockNumber - b.blockNumber;
            }
            return a.logIndex - b.logIndex;
        });

        for (const event of allEvents) {
            await this.processEvent(event);
        }
    }

    setupEventListeners() {
        // 监听质押事件
        this.stakeContract.on('Staked', async (user, amount, timestamp, event) => {
            console.log(`💰 Stake event: ${user} staked ${ethers.utils.formatEther(amount)} ETH`);
            await this.handleStakeEvent(event);
        });

        this.stakeContract.on('Unstaked', async (user, amount, timestamp, event) => {
            console.log(`📤 Unstake event: ${user} unstaked ${ethers.utils.formatEther(amount)} ETH`);
            await this.handleUnstakeEvent(event);
        });

        this.stakeContract.on('RewardsClaimed', async (user, amount, timestamp, event) => {
            console.log(`🎁 Rewards claimed: ${user} claimed ${ethers.utils.formatEther(amount)} MNT`);
            await this.handleRewardsClaimedEvent(event);
        });

        // EmergencyWithdraw 是函数不是事件，不需要监听

        // 监听代币事件
        this.tokenContract.on('Transfer', async (from, to, amount, event) => {
            // 只处理从合约发出的转账（奖励分发）
            if (from === this.stakeContract.address) {
                console.log(`🪙 Token transfer: ${ethers.utils.formatEther(amount)} MNT to ${to}`);
                await this.handleTokenTransferEvent(event);
            }
        });

        // 监听新区块
        this.provider.on('block', async (blockNumber) => {
            if (blockNumber > this.lastProcessedBlock) {
                await this.saveLastProcessedBlock(blockNumber);
                this.lastProcessedBlock = blockNumber;
            }
        });

        console.log('👂 Event listeners set up');
    }

    async processEvent(event) {
        try {
            // 保存原始事件到数据库
            await this.saveContractEvent(event);

            // 根据事件类型处理
            switch (event.event) {
                case 'Staked':
                    await this.handleStakeEvent(event);
                    break;
                case 'Unstaked':
                    await this.handleUnstakeEvent(event);
                    break;
                case 'RewardsClaimed':
                    await this.handleRewardsClaimedEvent(event);
                    break;
                // EmergencyWithdraw 不是事件，已移除
                case 'Transfer':
                    if (event.address === this.tokenContract.address) {
                        await this.handleTokenTransferEvent(event);
                    }
                    break;
            }
        } catch (error) {
            console.error(`Error processing event ${event.event}:`, error);
        }
    }

    async saveContractEvent(event) {
        try {
            await this.supabaseService.supabase
                .from('contract_events')
                .insert([{
                    event_name: event.event,
                    contract_address: event.address,
                    transaction_hash: event.transactionHash,
                    block_number: event.blockNumber,
                    log_index: event.logIndex,
                    user_address: event.args?.user || event.args?.to || null,
                    event_data: {
                        args: event.args ? Object.keys(event.args).reduce((acc, key) => {
                            if (isNaN(key)) {
                                acc[key] = event.args[key].toString();
                            }
                            return acc;
                        }, {}) : {},
                        topics: event.topics
                    }
                }]);
        } catch (error) {
            console.error('Error saving contract event:', error);
        }
    }

    async handleStakeEvent(event) {
        const { user, amount, timestamp } = event.args;
        
        // 创建质押记录
        await this.supabaseService.createStakeRecord({
            userWallet: user,
            amount: ethers.utils.formatEther(amount),
            transactionHash: event.transactionHash,
            blockNumber: event.blockNumber,
            stakeType: 'stake'
        });

        // 更新用户信息
        await this.updateUserStats(user);

        // 创建通知
        await this.supabaseService.createNotification({
            userWallet: user,
            title: 'Stake Successful',
            message: `You have successfully staked ${ethers.utils.formatEther(amount)} ETH`,
            type: 'success'
        });

        // 更新每日统计
        await this.updateDailyStats();
    }

    async handleUnstakeEvent(event) {
        const { user, amount, timestamp } = event.args;
        
        // 创建质押记录
        await this.supabaseService.createStakeRecord({
            userWallet: user,
            amount: ethers.utils.formatEther(amount),
            transactionHash: event.transactionHash,
            blockNumber: event.blockNumber,
            stakeType: 'unstake'
        });

        // 更新用户信息
        await this.updateUserStats(user);

        // 创建通知
        await this.supabaseService.createNotification({
            userWallet: user,
            title: 'Unstake Successful',
            message: `You have successfully unstaked ${ethers.utils.formatEther(amount)} ETH`,
            type: 'success'
        });

        // 更新每日统计
        await this.updateDailyStats();
    }

    async handleRewardsClaimedEvent(event) {
        const { user, amount, timestamp } = event.args;
        
        // 创建奖励记录
        await this.supabaseService.createRewardRecord({
            userWallet: user,
            amount: ethers.utils.formatEther(amount),
            transactionHash: event.transactionHash,
            blockNumber: event.blockNumber,
            rewardType: 'claim'
        });

        // 更新用户信息
        await this.updateUserStats(user);

        // 创建通知
        await this.supabaseService.createNotification({
            userWallet: user,
            title: 'Rewards Claimed',
            message: `You have claimed ${ethers.utils.formatEther(amount)} MNT tokens as rewards`,
            type: 'success'
        });
    }

    async handleEmergencyWithdrawEvent(event) {
        const { user, amount } = event.args;
        
        // 创建质押记录
        await this.supabaseService.createStakeRecord({
            userWallet: user,
            amount: ethers.utils.formatEther(amount),
            transactionHash: event.transactionHash,
            blockNumber: event.blockNumber,
            stakeType: 'emergency_withdraw'
        });

        // 更新用户信息
        await this.updateUserStats(user);

        // 创建通知
        await this.supabaseService.createNotification({
            userWallet: user,
            title: 'Emergency Withdraw',
            message: `Emergency withdrawal of ${ethers.utils.formatEther(amount)} ETH completed`,
            type: 'warning'
        });
    }

    async handleTokenTransferEvent(event) {
        // 处理代币转账事件（主要是奖励分发）
        const { from, to, value } = event.args;
        
        if (from === this.stakeContract.address) {
            console.log(`🎁 Reward distributed: ${ethers.utils.formatEther(value)} MNT to ${to}`);
        }
    }

    async updateUserStats(userWallet) {
        try {
            // 获取用户当前质押信息
            const stakeInfo = await this.stakeContract.getUserStakeInfo(userWallet);
            const pendingRewards = await this.stakeContract.getPendingRewards(userWallet);

            // 获取用户历史记录统计
            const stakeRecords = await this.supabaseService.getUserStakeRecords(userWallet);
            const rewardRecords = await this.supabaseService.getUserRewardRecords(userWallet);

            const totalRewardsEarned = rewardRecords.data?.reduce((sum, record) => 
                sum + parseFloat(record.amount), 0) || 0;

            // 更新用户信息
            await this.supabaseService.updateUser(userWallet, {
                total_staked: ethers.utils.formatEther(stakeInfo.amount),
                total_rewards_earned: totalRewardsEarned.toString(),
                stake_count: stakeRecords.data?.length || 0,
                last_stake_date: new Date().toISOString()
            });
        } catch (error) {
            console.error('Error updating user stats:', error);
        }
    }

    async updateDailyStats() {
        try {
            // 获取合约统计信息
            const contractStats = await this.stakeContract.getContractStats();
            const [totalStaked, totalRewardsDistributed, contractBalance] = contractStats;

            // 获取用户总数
            const { count: totalUsers } = await this.supabaseService.supabase
                .from('users')
                .select('*', { count: 'exact', head: true });

            // 计算平均质押金额
            const averageStakeAmount = totalUsers > 0 ? 
                parseFloat(ethers.utils.formatEther(totalStaked)) / totalUsers : 0;

            // 更新每日统计
            await this.supabaseService.updateDailyStats({
                totalStaked: ethers.utils.formatEther(totalStaked),
                totalUsers: totalUsers || 0,
                totalRewardsDistributed: ethers.utils.formatEther(totalRewardsDistributed),
                averageStakeAmount: averageStakeAmount.toString()
            });
        } catch (error) {
            console.error('Error updating daily stats:', error);
        }
    }

    startPeriodicCheck() {
        // 每5分钟检查一次是否有遗漏的事件
        setInterval(async () => {
            try {
                const currentBlock = await this.provider.getBlockNumber();
                if (currentBlock > this.lastProcessedBlock + 10) {
                    console.log('🔍 Checking for missed events...');
                    await this.processBlockRange(this.lastProcessedBlock + 1, currentBlock);
                    await this.saveLastProcessedBlock(currentBlock);
                    this.lastProcessedBlock = currentBlock;
                }
            } catch (error) {
                console.error('Error in periodic check:', error);
            }
        }, 5 * 60 * 1000); // 5分钟
    }

    async stopListening() {
        if (!this.isListening) {
            console.log('⚠️ Event listener is not running');
            return;
        }

        this.isListening = false;
        
        // 移除所有监听器
        this.stakeContract.removeAllListeners();
        this.tokenContract.removeAllListeners();
        this.provider.removeAllListeners();

        console.log('🛑 Event listener stopped');
    }

    async getStatus() {
        return {
            isListening: this.isListening,
            lastProcessedBlock: this.lastProcessedBlock,
            currentBlock: await this.provider.getBlockNumber(),
            stakeContractAddress: this.stakeContract?.address,
            tokenContractAddress: this.tokenContract?.address
        };
    }
}

module.exports = EventListener;