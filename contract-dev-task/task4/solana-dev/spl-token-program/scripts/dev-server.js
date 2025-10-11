const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

class DevServer {
    constructor(port = 3000) {
        this.port = port;
        this.appDir = path.join(__dirname, '../app');
        this.validatorProcess = null;
    }

    async start() {
        console.log('🚀 启动SPL Token Program开发服务器...');

        // 启动Solana测试验证器
        await this.startValidator();

        // 启动HTTP服务器
        this.startHttpServer();
    }

    startValidator() {
        return new Promise((resolve, reject) => {
            console.log('🔗 启动Solana测试验证器...');
            
            // 检查是否已有验证器在运行
            exec('solana cluster-version', (error, stdout, stderr) => {
                if (!error) {
                    console.log('✅ 检测到运行中的验证器');
                    resolve();
                    return;
                }

                // 启动新的验证器
                this.validatorProcess = exec('solana-test-validator --reset', (error, stdout, stderr) => {
                    if (error) {
                        console.error('❌ 验证器启动失败:', error);
                        reject(error);
                        return;
                    }
                });

                // 等待验证器启动
                setTimeout(() => {
                    console.log('✅ 验证器启动完成');
                    resolve();
                }, 5000);
            });
        });
    }

    startHttpServer() {
        const server = http.createServer((req, res) => {
            let filePath = path.join(this.appDir, req.url === '/' ? 'index.html' : req.url);
            
            // 安全检查
            if (!filePath.startsWith(this.appDir)) {
                res.writeHead(403);
                res.end('Forbidden');
                return;
            }

            // 获取文件扩展名
            const extname = path.extname(filePath).toLowerCase();
            const mimeTypes = {
                '.html': 'text/html',
                '.js': 'text/javascript',
                '.css': 'text/css',
                '.json': 'application/json',
                '.png': 'image/png',
                '.jpg': 'image/jpg',
                '.gif': 'image/gif',
                '.svg': 'image/svg+xml',
                '.wav': 'audio/wav',
                '.mp4': 'video/mp4',
                '.woff': 'application/font-woff',
                '.ttf': 'application/font-ttf',
                '.eot': 'application/vnd.ms-fontobject',
                '.otf': 'application/font-otf',
                '.wasm': 'application/wasm'
            };

            const contentType = mimeTypes[extname] || 'application/octet-stream';

            fs.readFile(filePath, (error, content) => {
                if (error) {
                    if (error.code === 'ENOENT') {
                        res.writeHead(404);
                        res.end('文件未找到');
                    } else {
                        res.writeHead(500);
                        res.end('服务器错误: ' + error.code);
                    }
                } else {
                    res.writeHead(200, { 
                        'Content-Type': contentType,
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                    });
                    res.end(content, 'utf-8');
                }
            });
        });

        server.listen(this.port, () => {
            console.log(`🌐 HTTP服务器运行在 http://localhost:${this.port}`);
            console.log('\n📝 开发指南:');
            console.log('   1. 在浏览器中打开 http://localhost:3000');
            console.log('   2. 点击"连接钱包"获取测试SOL');
            console.log('   3. 初始化代币铸造');
            console.log('   4. 测试代币操作功能');
            console.log('\n⚡ 快捷命令:');
            console.log('   - 构建程序: anchor build');
            console.log('   - 部署程序: anchor deploy');
            console.log('   - 运行测试: anchor test');
            console.log('   - 停止服务器: Ctrl+C');
        });

        // 优雅关闭
        process.on('SIGINT', () => {
            console.log('\n🛑 正在关闭服务器...');
            
            if (this.validatorProcess) {
                this.validatorProcess.kill();
                console.log('✅ 验证器已停止');
            }
            
            server.close(() => {
                console.log('✅ HTTP服务器已停止');
                process.exit(0);
            });
        });
    }
}

// 启动开发服务器
if (require.main === module) {
    const port = process.argv[2] || 3000;
    const devServer = new DevServer(port);
    devServer.start().catch(console.error);
}

module.exports = DevServer;