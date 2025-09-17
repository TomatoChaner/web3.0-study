# 🚀 Railway 后端部署指南

## 📋 部署概述

本指南将帮助你将 Stake Contract 后端服务部署到 Railway 平台。Railway 是一个现代化的云平台，特别适合 Node.js 应用的部署。

## 🎯 部署架构

```
前端 (Vercel)
    ↓ HTTPS
后端 API (Railway)
    ↓
PostgreSQL (Railway)
    ↓
区块链网络 (Sepolia/Mainnet)
```

## 📦 准备工作

### 1. 安装 Railway CLI

```bash
# 使用 npm 安装
npm install -g @railway/cli

# 或使用 curl 安装
curl -fsSL https://railway.app/install.sh | sh
```

### 2. 登录 Railway

```bash
railway login
```

### 3. 准备环境变量

复制环境变量模板：

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入实际值：

- `RPC_URL`: Infura 或 Alchemy 的 RPC 端点
- `SUPABASE_*`: Supabase 项目配置
- `STAKE_CONTRACT_ADDRESS`: 已部署的合约地址
- 其他必需的配置项

## 🚀 快速部署

### 方法一：使用部署脚本 (推荐)

```bash
# 首次部署 - 初始化项目
./deploy-railway.sh init

# 部署应用
./deploy-railway.sh deploy

# 查看日志
./deploy-railway.sh logs

# 查看状态
./deploy-railway.sh status
```

### 方法二：手动部署

1. **初始化项目**

   ```bash
   railway init
   ```

2. **添加 PostgreSQL 数据库**

   ```bash
   railway add postgresql
   ```

3. **设置环境变量**

   ```bash
   # 从 .env 文件批量设置
   railway variables set $(cat .env | grep -v '^#' | xargs)
   ```

4. **部署应用**
   ```bash
   railway up
   ```

## 🔧 环境变量配置

### 必需的环境变量

| 变量名                   | 描述            | 示例值                                  |
| ------------------------ | --------------- | --------------------------------------- |
| `NODE_ENV`               | 运行环境        | `production`                            |
| `RPC_URL`                | 区块链 RPC 端点 | `https://sepolia.infura.io/v3/YOUR_KEY` |
| `CHAIN_ID`               | 区块链网络 ID   | `11155111` (Sepolia)                    |
| `STAKE_CONTRACT_ADDRESS` | 质押合约地址    | `0x...`                                 |
| `METANODE_TOKEN_ADDRESS` | 代币合约地址    | `0x...`                                 |
| `FRONTEND_URL`           | 前端域名        | `https://your-app.vercel.app`           |
| `JWT_SECRET`             | JWT 密钥        | `your_secret_key`                       |

### Railway 自动提供的变量

- `PORT`: Railway 自动设置的端口
- `DATABASE_URL`: PostgreSQL 连接字符串 (如果添加了数据库)

## 📁 项目结构

```
stake-contract/
├── services/
│   ├── api.js              # 主 API 服务器
│   ├── eventListener.js    # 区块链事件监听器
│   └── supabase.js         # 数据库服务
├── contracts/              # 智能合约
├── scripts/                # 部署和工具脚本
├── railway.json           # Railway 配置
├── Dockerfile             # Docker 配置
├── deploy-railway.sh      # 部署脚本
└── package.json           # 项目配置
```

## 🔄 部署流程

### 1. 构建阶段

- 安装依赖 (`npm install`)
- 编译智能合约 (`npm run compile`)

### 2. 启动阶段

- 设置环境变量
- 启动 API 服务器 (`npm run start:production`)
- 健康检查 (`/health` 端点)

### 3. 运行时

- API 服务监听 HTTP 请求
- 事件监听器监控区块链事件
- 数据库存储应用状态

## 🔍 监控和调试

### 查看日志

```bash
# 实时日志
railway logs

# 或使用脚本
./deploy-railway.sh logs
```

### 检查服务状态

```bash
# 服务状态
railway status

# 获取应用 URL
railway domain

# 或使用脚本
./deploy-railway.sh status
```

### 健康检查

访问 `https://your-app.railway.app/health` 检查服务状态

## 🛠️ 常用命令

```bash
# 项目管理
railway init                    # 初始化项目
railway link                    # 链接到现有项目
railway unlink                  # 取消链接

# 环境变量
railway variables               # 查看所有变量
railway variables set KEY=VALUE # 设置变量
railway variables delete KEY    # 删除变量

# 部署和服务
railway up                      # 部署应用
railway down                    # 停止服务
railway redeploy               # 重新部署

# 数据库
railway add postgresql         # 添加 PostgreSQL
railway connect postgresql     # 连接数据库

# 域名管理
railway domain                 # 查看域名
railway domain add example.com # 添加自定义域名
```

## 🐛 常见问题

### 1. 部署失败

**问题**: 构建或启动失败
**解决方案**:

- 检查 `package.json` 中的 `start` 脚本
- 确保所有依赖都在 `dependencies` 中
- 查看部署日志: `railway logs`

### 2. 环境变量问题

**问题**: 应用无法读取环境变量
**解决方案**:

- 确认变量已设置: `railway variables`
- 检查变量名拼写
- 重新部署: `railway redeploy`

### 3. 数据库连接失败

**问题**: 无法连接到 PostgreSQL
**解决方案**:

- 确认已添加数据库: `railway add postgresql`
- 检查 `DATABASE_URL` 变量
- 验证数据库迁移是否成功

### 4. 合约交互失败

**问题**: 无法与智能合约交互
**解决方案**:

- 验证 `RPC_URL` 可访问
- 确认合约地址正确
- 检查网络 ID 匹配

## 🔒 安全最佳实践

### 1. 环境变量安全

- 不要在代码中硬编码密钥
- 使用强密码和随机密钥
- 定期轮换 API 密钥

### 2. 网络安全

- 配置正确的 CORS 策略
- 使用 HTTPS (Railway 自动提供)
- 实施速率限制

### 3. 数据库安全

- 使用连接池
- 实施适当的访问控制
- 定期备份数据

## 📊 性能优化

### 1. 应用优化

- 使用连接池管理数据库连接
- 实施缓存策略
- 优化 API 响应时间

### 2. 监控设置

- 设置健康检查
- 监控应用指标
- 配置告警通知

## 🔄 CI/CD 集成

### GitHub Actions 示例

```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: "18"
      - run: npm ci
      - run: npm test
      - uses: railway/cli@v2
        with:
          command: up
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

## 📞 支持和资源

- [Railway 官方文档](https://docs.railway.app/)
- [Railway 社区](https://railway.app/discord)
- [部署故障排除](https://docs.railway.app/troubleshoot/fixing-common-errors)

---

🎉 **部署完成后，你的后端 API 就可以为前端 DApp 提供服务了！**

记得更新前端的 API 端点配置，指向你的 Railway 应用 URL。
