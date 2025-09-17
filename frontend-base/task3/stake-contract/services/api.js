const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { ethers } = require('ethers');
const SupabaseService = require('./supabase');
const EventListener = require('./eventListener');
require('dotenv').config();

class APIServer {
    constructor() {
        this.app = express();
        this.port = process.env.API_PORT || 3001;
        this.supabaseService = new SupabaseService();
        this.eventListener = new EventListener();
        this.provider = new ethers.JsonRpcProvider(process.env.RPC_URL || 'http://127.0.0.1:8545');
        
        this.setupMiddleware();
        this.setupRoutes();
        this.setupErrorHandling();
    }

    setupMiddleware() {
        // 安全中间件
        this.app.use(helmet());
        
        // CORS配置
        const allowedOrigins = [
            'http://localhost:3000', // 本地开发
            'http://localhost:3001', // 本地API测试
            process.env.FRONTEND_URL, // 环境变量指定的前端URL
        ].filter(Boolean); // 过滤掉undefined值

        // 处理逗号分隔的CORS_ORIGIN
        if (process.env.CORS_ORIGIN) {
            const corsOrigins = process.env.CORS_ORIGIN.split(',').map(origin => origin.trim());
            allowedOrigins.push(...corsOrigins);
        }

        // 如果是生产环境，添加常见的Vercel域名模式
        if (process.env.NODE_ENV === 'production') {
            allowedOrigins.push(
                /^https:\/\/.*\.vercel\.app$/,
                /^https:\/\/.*\.vercel\.com$/
            );
        }

        this.app.use(cors({
            origin: (origin, callback) => {
                // 允许没有origin的请求（如移动应用、Postman等）
                if (!origin) return callback(null, true);
                
                // 检查origin是否在允许列表中
                const isAllowed = allowedOrigins.some(allowedOrigin => {
                    if (typeof allowedOrigin === 'string') {
                        return origin === allowedOrigin;
                    }
                    if (allowedOrigin instanceof RegExp) {
                        return allowedOrigin.test(origin);
                    }
                    return false;
                });
                
                if (isAllowed) {
                    callback(null, true);
                } else {
                    console.warn(`CORS blocked origin: ${origin}`);
                    callback(new Error('Not allowed by CORS'));
                }
            },
            credentials: true,
            methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
            allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
        }));

        // 请求解析
        this.app.use(express.json({ limit: '10mb' }));
        this.app.use(express.urlencoded({ extended: true }));

        // 请求限制
        const limiter = rateLimit({
            windowMs: 15 * 60 * 1000, // 15分钟
            max: 100, // 每个IP最多100个请求
            message: 'Too many requests from this IP'
        });
        this.app.use('/api/', limiter);

        // 请求日志
        this.app.use((req, res, next) => {
            console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
            next();
        });
    }

    setupRoutes() {
        // 健康检查
        this.app.get('/health', async (req, res) => {
            try {
                const supabaseHealth = await this.supabaseService.healthCheck();
                const eventListenerStatus = await this.eventListener.getStatus();
                const blockNumber = await this.provider.getBlockNumber();

                res.json({
                    status: 'healthy',
                    timestamp: new Date().toISOString(),
                    services: {
                        supabase: supabaseHealth.success,
                        eventListener: eventListenerStatus.isListening,
                        blockchain: blockNumber > 0
                    },
                    blockNumber
                });
            } catch (error) {
                res.status(500).json({
                    status: 'unhealthy',
                    error: error.message
                });
            }
        });

        // API路由
        this.app.use('/api/users', this.createUserRoutes());
        this.app.use('/api/stakes', this.createStakeRoutes());
        this.app.use('/api/rewards', this.createRewardRoutes());
        this.app.use('/api/stats', this.createStatsRoutes());
        this.app.use('/api/notifications', this.createNotificationRoutes());
        this.app.use('/api/admin', this.createAdminRoutes());
    }

    createUserRoutes() {
        const router = express.Router();

        // 获取用户信息
        router.get('/:walletAddress', async (req, res) => {
            try {
                const { walletAddress } = req.params;
                
                if (!ethers.utils.isAddress(walletAddress)) {
                    return res.status(400).json({ error: 'Invalid wallet address' });
                }

                const result = await this.supabaseService.getUserByWallet(walletAddress);
                
                if (!result.success) {
                    return res.status(500).json({ error: result.error });
                }

                res.json({ user: result.data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 创建或更新用户
        router.post('/', async (req, res) => {
            try {
                const { walletAddress, email, username } = req.body;
                
                if (!ethers.utils.isAddress(walletAddress)) {
                    return res.status(400).json({ error: 'Invalid wallet address' });
                }

                // 检查用户是否存在
                const existingUser = await this.supabaseService.getUserByWallet(walletAddress);
                
                let result;
                if (existingUser.data) {
                    // 更新用户
                    result = await this.supabaseService.updateUser(walletAddress, {
                        email,
                        username
                    });
                } else {
                    // 创建新用户
                    result = await this.supabaseService.createUser({
                        walletAddress,
                        email,
                        username
                    });
                }

                if (!result.success) {
                    return res.status(500).json({ error: result.error });
                }

                res.json({ user: result.data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 获取用户完整统计
        router.get('/:walletAddress/stats', async (req, res) => {
            try {
                const { walletAddress } = req.params;
                
                if (!ethers.utils.isAddress(walletAddress)) {
                    return res.status(400).json({ error: 'Invalid wallet address' });
                }

                const { data, error } = await this.supabaseService.supabase
                    .rpc('get_user_complete_stats', { wallet_addr: walletAddress.toLowerCase() });

                if (error) {
                    return res.status(500).json({ error: error.message });
                }

                res.json({ stats: data[0] || null });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        return router;
    }

    createStakeRoutes() {
        const router = express.Router();

        // 获取用户质押记录
        router.get('/user/:walletAddress', async (req, res) => {
            try {
                const { walletAddress } = req.params;
                const { limit = 50, offset = 0 } = req.query;
                
                if (!ethers.utils.isAddress(walletAddress)) {
                    return res.status(400).json({ error: 'Invalid wallet address' });
                }

                const { data, error } = await this.supabaseService.supabase
                    .from('stake_records')
                    .select('*')
                    .eq('user_wallet', walletAddress.toLowerCase())
                    .order('created_at', { ascending: false })
                    .range(offset, offset + limit - 1);

                if (error) {
                    return res.status(500).json({ error: error.message });
                }

                res.json({ stakes: data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 获取质押记录详情
        router.get('/:transactionHash', async (req, res) => {
            try {
                const { transactionHash } = req.params;

                const { data, error } = await this.supabaseService.supabase
                    .from('stake_records')
                    .select('*')
                    .eq('transaction_hash', transactionHash)
                    .single();

                if (error) {
                    return res.status(500).json({ error: error.message });
                }

                res.json({ stake: data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 获取最新质押记录
        router.get('/', async (req, res) => {
            try {
                const { limit = 20 } = req.query;

                const { data, error } = await this.supabaseService.supabase
                    .from('stake_records')
                    .select(`
                        *,
                        users!inner(username, wallet_address)
                    `)
                    .order('created_at', { ascending: false })
                    .limit(limit);

                if (error) {
                    return res.status(500).json({ error: error.message });
                }

                res.json({ stakes: data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        return router;
    }

    createRewardRoutes() {
        const router = express.Router();

        // 获取用户奖励记录
        router.get('/user/:walletAddress', async (req, res) => {
            try {
                const { walletAddress } = req.params;
                const { limit = 50, offset = 0 } = req.query;
                
                if (!ethers.utils.isAddress(walletAddress)) {
                    return res.status(400).json({ error: 'Invalid wallet address' });
                }

                const { data, error } = await this.supabaseService.supabase
                    .from('reward_records')
                    .select('*')
                    .eq('user_wallet', walletAddress.toLowerCase())
                    .order('created_at', { ascending: false })
                    .range(offset, offset + limit - 1);

                if (error) {
                    return res.status(500).json({ error: error.message });
                }

                res.json({ rewards: data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 获取奖励统计
        router.get('/user/:walletAddress/summary', async (req, res) => {
            try {
                const { walletAddress } = req.params;
                
                if (!ethers.utils.isAddress(walletAddress)) {
                    return res.status(400).json({ error: 'Invalid wallet address' });
                }

                const { data, error } = await this.supabaseService.supabase
                    .from('reward_records')
                    .select('amount, created_at')
                    .eq('user_wallet', walletAddress.toLowerCase());

                if (error) {
                    return res.status(500).json({ error: error.message });
                }

                const totalRewards = data.reduce((sum, record) => sum + parseFloat(record.amount), 0);
                const rewardCount = data.length;
                const lastRewardDate = data.length > 0 ? data[0].created_at : null;

                res.json({
                    summary: {
                        totalRewards: totalRewards.toString(),
                        rewardCount,
                        lastRewardDate,
                        averageReward: rewardCount > 0 ? (totalRewards / rewardCount).toString() : '0'
                    }
                });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        return router;
    }

    createStatsRoutes() {
        const router = express.Router();

        // 获取总体统计
        router.get('/overview', async (req, res) => {
            try {
                // 获取最新的每日统计
                const { data: dailyStats, error: dailyError } = await this.supabaseService.supabase
                    .from('daily_stats')
                    .select('*')
                    .order('date', { ascending: false })
                    .limit(1);

                if (dailyError) {
                    return res.status(500).json({ error: dailyError.message });
                }

                // 获取活跃用户统计
                const { data: activeUsers, error: activeError } = await this.supabaseService.supabase
                    .from('daily_active_users')
                    .select('*')
                    .order('date', { ascending: false })
                    .limit(7);

                if (activeError) {
                    return res.status(500).json({ error: activeError.message });
                }

                // 获取排行榜
                const { data: leaderboard, error: leaderError } = await this.supabaseService.supabase
                    .from('user_stats')
                    .select('wallet_address, username, calculated_total_staked, calculated_total_rewards')
                    .order('calculated_total_staked', { ascending: false })
                    .limit(10);

                if (leaderError) {
                    return res.status(500).json({ error: leaderError.message });
                }

                res.json({
                    overview: dailyStats[0] || {},
                    activeUsers,
                    leaderboard
                });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 获取历史统计
        router.get('/history', async (req, res) => {
            try {
                const { days = 30 } = req.query;

                const result = await this.supabaseService.getDailyStats(parseInt(days));
                
                if (!result.success) {
                    return res.status(500).json({ error: result.error });
                }

                res.json({ history: result.data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 获取实时统计
        router.get('/realtime', async (req, res) => {
            try {
                // 从区块链获取实时数据
                const deployment = require('../deployments/deployment.json');
                const StakeContractABI = require('../artifacts/contracts/StakeContract.sol/StakeContract.json').abi;
                
                const stakeContract = new ethers.Contract(
                    deployment.stakeContract.address,
                    StakeContractABI,
                    this.provider
                );

                const [totalStaked, totalRewardsDistributed, contractBalance] = 
                    await stakeContract.getContractStats();

                const currentBlock = await this.provider.getBlockNumber();

                res.json({
                    realtime: {
                        totalStaked: ethers.utils.formatEther(totalStaked),
                        totalRewardsDistributed: ethers.utils.formatEther(totalRewardsDistributed),
                        contractBalance: ethers.utils.formatEther(contractBalance),
                        currentBlock,
                        timestamp: new Date().toISOString()
                    }
                });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        return router;
    }

    createNotificationRoutes() {
        const router = express.Router();

        // 获取用户通知
        router.get('/user/:walletAddress', async (req, res) => {
            try {
                const { walletAddress } = req.params;
                const { unreadOnly = false, limit = 50 } = req.query;
                
                if (!ethers.utils.isAddress(walletAddress)) {
                    return res.status(400).json({ error: 'Invalid wallet address' });
                }

                const result = await this.supabaseService.getUserNotifications(
                    walletAddress, 
                    unreadOnly === 'true'
                );
                
                if (!result.success) {
                    return res.status(500).json({ error: result.error });
                }

                res.json({ notifications: result.data.slice(0, limit) });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 标记通知为已读
        router.patch('/:notificationId/read', async (req, res) => {
            try {
                const { notificationId } = req.params;

                const result = await this.supabaseService.markNotificationAsRead(notificationId);
                
                if (!result.success) {
                    return res.status(500).json({ error: result.error });
                }

                res.json({ notification: result.data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 创建通知（管理员功能）
        router.post('/', async (req, res) => {
            try {
                const { userWallet, title, message, type } = req.body;
                
                if (!ethers.utils.isAddress(userWallet)) {
                    return res.status(400).json({ error: 'Invalid wallet address' });
                }

                const result = await this.supabaseService.createNotification({
                    userWallet,
                    title,
                    message,
                    type
                });
                
                if (!result.success) {
                    return res.status(500).json({ error: result.error });
                }

                res.json({ notification: result.data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        return router;
    }

    createAdminRoutes() {
        const router = express.Router();

        // 获取事件监听器状态
        router.get('/event-listener/status', async (req, res) => {
            try {
                const status = await this.eventListener.getStatus();
                res.json({ status });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 启动事件监听器
        router.post('/event-listener/start', async (req, res) => {
            try {
                await this.eventListener.startListening();
                res.json({ message: 'Event listener started successfully' });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 停止事件监听器
        router.post('/event-listener/stop', async (req, res) => {
            try {
                await this.eventListener.stopListening();
                res.json({ message: 'Event listener stopped successfully' });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 获取系统配置
        router.get('/config', async (req, res) => {
            try {
                const { data, error } = await this.supabaseService.supabase
                    .from('system_config')
                    .select('*')
                    .order('key');

                if (error) {
                    return res.status(500).json({ error: error.message });
                }

                res.json({ config: data });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        // 更新系统配置
        router.patch('/config/:key', async (req, res) => {
            try {
                const { key } = req.params;
                const { value } = req.body;

                const { data, error } = await this.supabaseService.supabase
                    .from('system_config')
                    .update({ value, updated_at: new Date().toISOString() })
                    .eq('key', key)
                    .select();

                if (error) {
                    return res.status(500).json({ error: error.message });
                }

                res.json({ config: data[0] });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });

        return router;
    }

    setupErrorHandling() {
        // 404处理
        this.app.use('*', (req, res) => {
            res.status(404).json({ error: 'Route not found' });
        });

        // 全局错误处理
        this.app.use((error, req, res, next) => {
            console.error('Global error handler:', error);
            res.status(500).json({ 
                error: 'Internal server error',
                message: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        });
    }

    async start() {
        try {
            // 初始化事件监听器
            await this.eventListener.initialize();
            
            // 启动服务器
            this.server = this.app.listen(this.port, () => {
                console.log(`🚀 API Server running on port ${this.port}`);
                console.log(`📊 Health check: http://localhost:${this.port}/health`);
                console.log(`🔗 API base URL: http://localhost:${this.port}/api`);
            });

            // 启动事件监听器
            await this.eventListener.startListening();

        } catch (error) {
            console.error('❌ Failed to start API server:', error);
            throw error;
        }
    }

    async stop() {
        try {
            // 停止事件监听器
            await this.eventListener.stopListening();
            
            // 停止服务器
            if (this.server) {
                this.server.close();
                console.log('🛑 API Server stopped');
            }
        } catch (error) {
            console.error('Error stopping API server:', error);
        }
    }
}

module.exports = APIServer;