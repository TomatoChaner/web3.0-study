#!/usr/bin/env node

const APIServer = require('../services/api');
const EventListener = require('../services/eventListener');
require('dotenv').config();

class ServiceManager {
    constructor() {
        this.apiServer = new APIServer();
        this.eventListener = new EventListener();
        this.isShuttingDown = false;
    }

    async start() {
        console.log('🚀 Starting Stake Contract Services...');
        console.log('=====================================');

        try {
            // 检查环境变量
            this.checkEnvironmentVariables();

            // 等待Hardhat节点启动
            console.log('⏳ Waiting for Hardhat node to start...');
            await this.waitForHardhatNode();

            // 启动API服务器（包含事件监听器）
            console.log('📡 Starting API Server...');
            await this.apiServer.start();

            console.log('✅ All services started successfully!');
            console.log('=====================================');
            console.log('📊 API Server: http://localhost:' + (process.env.API_PORT || 3001));
            console.log('🔍 Health Check: http://localhost:' + (process.env.API_PORT || 3001) + '/health');
            console.log('📚 API Documentation: http://localhost:' + (process.env.API_PORT || 3001) + '/api');
            console.log('=====================================');

            // 设置优雅关闭
            this.setupGracefulShutdown();

        } catch (error) {
            console.error('❌ Failed to start services:', error);
            process.exit(1);
        }
    }

    async waitForHardhatNode() {
        const { ethers } = require('ethers');
        const maxRetries = 30;
        const retryDelay = 2000; // 2秒

        for (let i = 0; i < maxRetries; i++) {
            try {
                const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
                await provider.getNetwork();
                console.log('✅ Hardhat node is ready!');
                return;
            } catch (error) {
                console.log(`⏳ Waiting for Hardhat node... (${i + 1}/${maxRetries})`);
                await new Promise(resolve => setTimeout(resolve, retryDelay));
            }
        }
        throw new Error('Hardhat node failed to start within timeout period');
    }

    checkEnvironmentVariables() {
        const requiredVars = [
            'RPC_URL',
            'SUPABASE_URL',
            'SUPABASE_ANON_KEY'
        ];

        const missingVars = requiredVars.filter(varName => !process.env[varName]);

        if (missingVars.length > 0) {
            console.error('❌ Missing required environment variables:');
            missingVars.forEach(varName => {
                console.error(`   - ${varName}`);
            });
            console.error('\nPlease check your .env file and ensure all required variables are set.');
            process.exit(1);
        }

        console.log('✅ Environment variables validated');
    }

    setupGracefulShutdown() {
        const shutdown = async (signal) => {
            if (this.isShuttingDown) {
                console.log('⚠️ Force shutdown...');
                process.exit(1);
            }

            this.isShuttingDown = true;
            console.log(`\n🛑 Received ${signal}, shutting down gracefully...`);

            try {
                // 停止API服务器
                await this.apiServer.stop();
                console.log('✅ Services stopped successfully');
                process.exit(0);
            } catch (error) {
                console.error('❌ Error during shutdown:', error);
                process.exit(1);
            }
        };

        // 监听关闭信号
        process.on('SIGTERM', () => shutdown('SIGTERM'));
        process.on('SIGINT', () => shutdown('SIGINT'));

        // 监听未捕获的异常
        process.on('uncaughtException', (error) => {
            console.error('❌ Uncaught Exception:', error);
            shutdown('uncaughtException');
        });

        process.on('unhandledRejection', (reason, promise) => {
            console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
            shutdown('unhandledRejection');
        });
    }

    async status() {
        try {
            const apiStatus = await this.apiServer.eventListener.getStatus();
            const supabaseHealth = await this.apiServer.supabaseService.healthCheck();

            console.log('📊 Service Status:');
            console.log('================');
            console.log('API Server:', this.apiServer.server ? '🟢 Running' : '🔴 Stopped');
            console.log('Event Listener:', apiStatus.isListening ? '🟢 Running' : '🔴 Stopped');
            console.log('Supabase:', supabaseHealth.success ? '🟢 Connected' : '🔴 Disconnected');
            console.log('Last Processed Block:', apiStatus.lastProcessedBlock);
            console.log('Current Block:', apiStatus.currentBlock);
            console.log('================');

            return {
                apiServer: !!this.apiServer.server,
                eventListener: apiStatus.isListening,
                supabase: supabaseHealth.success,
                lastProcessedBlock: apiStatus.lastProcessedBlock,
                currentBlock: apiStatus.currentBlock
            };
        } catch (error) {
            console.error('❌ Error getting status:', error);
            return null;
        }
    }
}

// CLI处理
async function main() {
    const serviceManager = new ServiceManager();
    const command = process.argv[2];

    switch (command) {
        case 'start':
            await serviceManager.start();
            break;
        
        case 'status':
            await serviceManager.status();
            process.exit(0);
            break;
        
        case 'help':
        case '--help':
        case '-h':
            console.log('Stake Contract Services Manager');
            console.log('==============================');
            console.log('Usage: node scripts/start-services.js [command]');
            console.log('');
            console.log('Commands:');
            console.log('  start    Start all services (default)');
            console.log('  status   Show service status');
            console.log('  help     Show this help message');
            console.log('');
            console.log('Environment Variables:');
            console.log('  RPC_URL              Blockchain RPC endpoint');
            console.log('  SUPABASE_URL         Supabase project URL');
            console.log('  SUPABASE_ANON_KEY    Supabase anonymous key');
            console.log('  API_PORT             API server port (default: 3001)');
            console.log('  FRONTEND_URL         Frontend URL for CORS (default: http://localhost:3000)');
            process.exit(0);
            break;
        
        default:
            // 默认启动服务
            await serviceManager.start();
            break;
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main().catch(error => {
        console.error('❌ Service manager error:', error);
        process.exit(1);
    });
}

module.exports = ServiceManager;