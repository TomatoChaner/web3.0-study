# MetaNode Staking 部署指南

## 概述

本指南将帮助您完整部署 MetaNode Staking 系统，包括智能合约、后端服务和数据库配置。

## 系统要求

### 开发环境
- Node.js >= 18.0.0
- npm >= 8.0.0
- Git

### 生产环境
- Linux/macOS 服务器
- Node.js >= 18.0.0
- PM2 (进程管理)
- Nginx (反向代理)
- SSL 证书

### 外部服务
- Ethereum RPC 节点 (Infura/Alchemy)
- Supabase 数据库
- Etherscan API Key

## 部署步骤

### 1. 环境准备

#### 1.1 克隆项目
```bash
git clone <repository-url>
cd stake-contract
```

#### 1.2 安装依赖
```bash
npm install
```

#### 1.3 配置环境变量
```bash
cp .env.example .env
```

编辑 `.env` 文件，填入实际配置：
```bash
# 网络配置
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID

# 私钥 (部署账户)
PRIVATE_KEY=your_private_key_here

# API Keys
ETHERSCAN_API_KEY=your_etherscan_api_key

# Supabase 配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# API 服务配置
API_PORT=3001
API_HOST=0.0.0.0
NODE_ENV=production
```

### 2. 数据库设置

#### 2.1 创建 Supabase 项目
1. 访问 [Supabase](https://supabase.com)
2. 创建新项目
3. 获取项目 URL 和 API Keys

#### 2.2 执行数据库迁移
1. 在 Supabase Dashboard 中打开 SQL Editor
2. 执行 `migrations/001_initial_schema.sql` 中的 SQL 语句
3. 验证表和函数创建成功

#### 2.3 配置行级安全 (RLS)
```sql
-- 在 Supabase SQL Editor 中执行
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE stake_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_records ENABLE ROW LEVEL SECURITY;
-- ... 其他表
```

### 3. 智能合约部署

#### 3.1 编译合约
```bash
npm run compile
```

#### 3.2 运行测试
```bash
npm run test
```

#### 3.3 部署到测试网 (Sepolia)
```bash
npm run deploy:sepolia
```

部署成功后，记录合约地址并更新 `.env` 文件：
```bash
STAKE_CONTRACT_ADDRESS=0x...
METANODE_TOKEN_ADDRESS=0x...
```

#### 3.4 验证合约
```bash
npm run verify:sepolia
```

#### 3.5 部署到主网 (生产环境)
```bash
# 确保私钥对应的账户有足够的 ETH
npm run deploy:mainnet
npm run verify:mainnet
```

### 4. 后端服务部署

#### 4.1 测试服务
```bash
# 测试 API 服务
npm run start:api

# 测试事件监听器
npm run start:listener
```

#### 4.2 生产环境部署

##### 使用 PM2
```bash
# 安装 PM2
npm install -g pm2

# 创建 PM2 配置文件
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'metanode-api',
      script: 'services/api.js',
      instances: 2,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: 'logs/api-error.log',
      out_file: 'logs/api-out.log',
      log_file: 'logs/api.log'
    },
    {
      name: 'metanode-listener',
      script: 'services/eventListener.js',
      instances: 1,
      env: {
        NODE_ENV: 'production'
      },
      error_file: 'logs/listener-error.log',
      out_file: 'logs/listener-out.log',
      log_file: 'logs/listener.log'
    }
  ]
};
EOF

# 启动服务
pm2 start ecosystem.config.js

# 保存 PM2 配置
pm2 save
pm2 startup
```

##### 使用 Docker (可选)
```bash
# 创建 Dockerfile
cat > Dockerfile << EOF
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3001

CMD ["npm", "run", "start:services"]
EOF

# 构建镜像
docker build -t metanode-staking .

# 运行容器
docker run -d \
  --name metanode-staking \
  -p 3001:3001 \
  --env-file .env \
  metanode-staking
```

### 5. Nginx 配置

#### 5.1 安装 Nginx
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# CentOS/RHEL
sudo yum install nginx
```

#### 5.2 配置反向代理
```bash
# 创建配置文件
sudo nano /etc/nginx/sites-available/metanode-staking

# 添加配置
server {
    listen 80;
    server_name your-domain.com;

    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /ws {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 启用配置
sudo ln -s /etc/nginx/sites-available/metanode-staking /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 5.3 SSL 配置 (Let's Encrypt)
```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 获取 SSL 证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 6. 监控和日志

#### 6.1 设置日志轮转
```bash
# 创建 logrotate 配置
sudo nano /etc/logrotate.d/metanode-staking

/path/to/stake-contract/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        pm2 reload all
    endscript
}
```

#### 6.2 健康检查脚本
```bash
#!/bin/bash
# health-check.sh

API_URL="http://localhost:3001/api/admin/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $API_URL)

if [ $RESPONSE -eq 200 ]; then
    echo "API is healthy"
    exit 0
else
    echo "API is unhealthy (HTTP $RESPONSE)"
    # 重启服务
    pm2 restart metanode-api
    exit 1
fi
```

#### 6.3 监控脚本
```bash
# 添加到 crontab
*/5 * * * * /path/to/health-check.sh >> /var/log/metanode-health.log 2>&1
```

### 7. 安全配置

#### 7.1 防火墙设置
```bash
# UFW (Ubuntu)
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable

# 或者 iptables
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -j DROP
```

#### 7.2 环境变量安全
```bash
# 设置文件权限
chmod 600 .env

# 使用系统环境变量 (推荐)
export PRIVATE_KEY="your_private_key"
export SUPABASE_SERVICE_ROLE_KEY="your_key"
```

### 8. 验证部署

#### 8.1 检查服务状态
```bash
# PM2 状态
pm2 status

# 端口监听
netstat -tlnp | grep :3001

# 日志检查
pm2 logs
```

#### 8.2 API 测试
```bash
# 健康检查
curl http://localhost:3001/api/admin/health

# 获取平台统计
curl http://localhost:3001/api/stats/platform
```

#### 8.3 合约交互测试
```bash
npm run interact
```

## 故障排除

### 常见问题

#### 1. 合约部署失败
- 检查私钥和 RPC URL
- 确保账户有足够的 ETH
- 检查网络连接

#### 2. 数据库连接失败
- 验证 Supabase 配置
- 检查网络连接
- 确认 API Key 权限

#### 3. 事件监听器不工作
- 检查合约地址配置
- 验证 RPC 节点连接
- 查看错误日志

#### 4. API 服务无响应
- 检查端口占用
- 查看 PM2 日志
- 验证环境变量

### 日志位置
- API 服务: `logs/api.log`
- 事件监听器: `logs/listener.log`
- Nginx: `/var/log/nginx/`
- PM2: `~/.pm2/logs/`

### 性能优化

#### 1. 数据库优化
- 添加适当索引
- 配置连接池
- 定期清理旧数据

#### 2. API 优化
- 启用响应压缩
- 配置缓存
- 使用 CDN

#### 3. 监控指标
- 响应时间
- 错误率
- 内存使用
- CPU 使用率

## 维护

### 定期任务
- 检查服务状态
- 更新依赖包
- 备份数据库
- 监控合约事件

### 更新流程
1. 备份当前版本
2. 测试新版本
3. 逐步部署
4. 验证功能
5. 回滚计划

## 支持

如遇到问题，请：
1. 查看日志文件
2. 检查配置文件
3. 参考故障排除指南
4. 联系技术支持