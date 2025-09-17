# MetaNode Staking Contract

## 📖 项目概述

MetaNode Staking Contract 是一个功能完整的以太坊质押平台，支持 ETH 质押并分发 MetaNode 代币作为奖励。系统包含智能合约、后端 API 服务、事件监听器和数据库集成，提供完整的 DeFi 质押解决方案。

## ✨ 核心特性

### 智能合约功能
- 🔒 **ETH 质押** - 支持灵活的 ETH 质押和赎回
- 🎁 **奖励分发** - 基于时间和数量的 MetaNode 代币奖励
- ⏰ **多种质押类型** - 灵活质押和固定期限质押
- 🛡️ **安全机制** - 紧急暂停、角色控制、重入保护
- 📊 **数学库** - 精确的奖励计算和复利计算
- 🔧 **管理功能** - APY 调整、奖励池管理、合约升级

### 后端服务
- 🌐 **RESTful API** - 完整的用户和质押管理接口
- 📡 **事件监听** - 实时监听区块链事件并同步数据
- 💾 **数据库集成** - Supabase 数据库存储和查询
- 🔄 **实时更新** - WebSocket 支持实时数据推送
- 📈 **统计分析** - 用户和平台数据统计
- 🔔 **通知系统** - 用户操作通知和提醒

### 技术特点
- ⚡ **高性能** - 优化的合约设计和数据库查询
- 🛡️ **安全可靠** - 基于 OpenZeppelin 的安全合约库
- 📱 **易于集成** - 标准化的 API 接口和文档
- 🔍 **可监控** - 完整的日志和健康检查机制

## 🚀 快速开始

### 1. 环境准备
```bash
# 克隆项目
git clone <repository-url>
cd stake-contract

# 安装依赖
npm install

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入必要的配置
```

### 2. 智能合约部署
```bash
# 编译合约
npm run compile

# 运行测试
npm run test

# 部署到本地网络
npm run node  # 新终端窗口
npm run deploy:local

# 部署到测试网
npm run deploy:sepolia
npm run verify:sepolia
```

### 3. 数据库设置
```bash
# 1. 创建 Supabase 项目
# 2. 在 Supabase Dashboard 执行 migrations/001_initial_schema.sql
# 3. 更新 .env 中的 Supabase 配置
```

### 4. 启动服务
```bash
# 启动所有服务 (开发环境)
npm run dev

# 或分别启动
npm run start:api      # API 服务
npm run start:listener # 事件监听器

# 生产环境
npm run start:services
# 启动本地节点
npx hardhat node

# 部署合约 (新终端)
npx hardhat run scripts/deploy.js --network localhost
```

### 验证部署
```bash
# 检查合约状态
npx hardhat run scripts/verify-deployment.js --network localhost
```

## 🎯 核心功能

### 1. 质押功能 (Stake)
- 用户可以质押指定数量的代币到指定的质押池
- 支持 Native Currency 和 ERC20 代币质押
- 自动计算和累积奖励

### 2. 解除质押功能 (Unstake)
- 用户可以申请解除质押
- 支持锁定期机制，保证系统安全性
- 分批解除质押支持

### 3. 奖励领取 (Claim Rewards)
- 用户可以随时领取已累积的 MetaNode 奖励
- 自动计算待领取奖励数量

### 4. 质押池管理
- 管理员可以添加新的质押池
- 支持更新池配置（权重、最小质押金额、锁定期等）
- 灵活的池权重分配机制

### 5. 合约治理
- 支持合约升级机制
- 可暂停/恢复特定操作
- 基于角色的权限管理

## 🔧 主要合约接口

### 用户操作
- `stake(uint256 _pid, uint256 _amount)` - 质押代币
- `unstake(uint256 _pid, uint256 _amount)` - 申请解除质押
- `claimReward(uint256 _pid)` - 领取奖励
- `withdraw(uint256 _pid, uint256 _requestIndex)` - 提取解质押的代币

### 管理员操作
- `addPool(address _stTokenAddress, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks)` - 添加质押池
- `updatePool(uint256 _pid, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks)` - 更新质押池
- `pause()` / `unpause()` - 暂停/恢复合约

### 查询接口
- `getPoolInfo(uint256 _pid)` - 获取池信息
- `getUserInfo(uint256 _pid, address _user)` - 获取用户信息
- `pendingReward(uint256 _pid, address _user)` - 查询待领取奖励

## 🛠️ 技术栈

### 智能合约开发
- **Solidity** `^0.8.19` - 智能合约编程语言
- **Hardhat** `^2.17.0` - 以太坊开发环境
- **OpenZeppelin** `^4.9.0` - 安全的智能合约库
  - `@openzeppelin/contracts/security/ReentrancyGuard.sol`
  - `@openzeppelin/contracts/access/AccessControl.sol`
  - `@openzeppelin/contracts/security/Pausable.sol`
  - `@openzeppelin/contracts/token/ERC20/IERC20.sol`

### 开发工具
- **Ethers.js** `^6.7.0` - 以太坊交互库
- **Hardhat-deploy** `^0.11.0` - 合约部署管理
- **Hardhat-gas-reporter** `^1.0.9` - Gas 使用分析
- **Solidity-coverage** `^0.8.0` - 代码覆盖率测试

### 测试框架
- **Mocha** `^10.2.0` - JavaScript 测试框架
- **Chai** `^4.3.0` - 断言库
- **Waffle** `^4.0.10` - 智能合约测试工具

### 数据库 & 后端
- **Supabase** - PostgreSQL 数据库服务
- **Node.js** `>=16.0.0` - 后端运行环境
- **@supabase/supabase-js** `^2.0.0` - Supabase 客户端

### 网络支持
- **Ethereum Mainnet** - 主网部署
- **Sepolia Testnet** - 测试网部署
- **Polygon** - Layer 2 扩容方案
- **Local Network** - 本地开发测试

### 代码质量
- **ESLint** - JavaScript/TypeScript 代码检查
- **Prettier** - 代码格式化
- **Solhint** - Solidity 代码检查
- **Husky** - Git hooks 管理

## 🏗️ 技术架构

### 混合架构设计
本项目采用链上合约 + 链下数据库的混合架构：

- **链上合约 (Ethereum/Polygon)**: 处理核心业务逻辑、资产安全和状态变更
- **链下数据库 (Supabase)**: 存储用户行为数据、历史记录和应用状态

### Supabase 数据库作用

#### 1. 用户行为追踪
- 质押/解质押操作历史
- 奖励领取记录
- 用户偏好设置

#### 2. 数据分析与统计
- 池子 TVL 历史数据
- 用户活跃度统计
- 奖励分发趋势

#### 3. 应用状态管理
- 用户界面配置
- 通知设置
- 交易状态缓存

#### 4. 性能优化
- 链上数据缓存
- 快速查询接口
- 实时数据同步

## 🔗 相关文档

- [前后端联动架构](./前后端联动架构.md) - 详细的前后端数据流和API设计

## 📁 项目结构

```
stake-contract/
├── contracts/                 # 智能合约源码
│   ├── StakeContract.sol     # 主质押合约
│   ├── MetaNodeToken.sol     # MetaNode 代币合约
│   ├── interfaces/           # 合约接口
│   │   ├── IStakeContract.sol
│   │   └── IMetaNodeToken.sol
│   └── libraries/            # 合约库
│       ├── SafeMath.sol
│       └── StakeLibrary.sol
├── scripts/                  # 部署和管理脚本
│   ├── deploy.js            # 合约部署脚本
│   ├── upgrade.js           # 合约升级脚本
│   ├── verify.js            # 合约验证脚本
│   └── setup-pools.js       # 初始化质押池
├── test/                    # 测试文件
│   ├── StakeContract.test.js
│   ├── MetaNodeToken.test.js
│   ├── integration/         # 集成测试
│   └── fixtures/            # 测试数据
├── lib/                     # 工具库
│   ├── supabase.js         # Supabase 客户端
│   ├── constants.js        # 常量定义
│   └── utils.js            # 工具函数
├── services/               # 后端服务
│   ├── sync-service.js     # 数据同步服务
│   ├── event-listener.js   # 事件监听器
│   └── analytics.js        # 数据分析服务
├── migrations/             # 数据库迁移
│   ├── 001_initial_schema.sql
│   ├── 002_add_indexes.sql
│   └── 003_setup_rls.sql
├── config/                 # 配置文件
│   ├── hardhat.config.js   # Hardhat 配置
│   ├── networks.js         # 网络配置
│   └── deployment.json     # 部署配置
├── docs/                   # 文档
│   ├── api.md             # API 文档
│   ├── deployment.md      # 部署指南
│   └── security.md        # 安全指南
├── .env.example           # 环境变量模板
├── package.json           # 项目依赖
├── hardhat.config.js      # Hardhat 主配置
└── README.md             # 项目说明
```

### 核心文件说明

#### 智能合约 (`contracts/`)
- **StakeContract.sol**: 主质押合约，实现质押、解质押、奖励分发等核心功能
- **MetaNodeToken.sol**: MetaNode 代币合约，用于奖励分发
- **interfaces/**: 合约接口定义，便于模块化开发和测试
- **libraries/**: 可重用的合约库，提供通用功能

#### 脚本 (`scripts/`)
- **deploy.js**: 自动化部署脚本，支持多网络部署
- **upgrade.js**: 合约升级脚本，支持代理模式升级
- **verify.js**: 合约源码验证脚本
- **setup-pools.js**: 初始化质押池配置

#### 测试 (`test/`)
- **单元测试**: 针对每个合约的功能测试
- **集成测试**: 端到端的系统测试
- **fixtures/**: 测试数据和模拟环境

#### 服务 (`services/`)
- **sync-service.js**: 监听区块链事件并同步到数据库
- **event-listener.js**: 实时事件监听和处理
- **analytics.js**: 数据分析和统计服务

#### 配置 (`config/`)
- **hardhat.config.js**: Hardhat 开发环境配置
- **networks.js**: 支持的区块链网络配置
- **deployment.json**: 部署后的合约地址记录

## 📊 数据结构

### Pool 结构
```solidity
struct Pool {
    address stTokenAddress;      // 质押代币地址
    uint256 poolWeight;          // 池权重
    uint256 lastRewardBlock;     // 最后奖励计算区块
    uint256 accMetaNodePerST;    // 每个质押代币累积的奖励
    uint256 stTokenAmount;       // 池中总质押代币量
    uint256 minDepositAmount;    // 最小质押金额
    uint256 unstakeLockedBlocks; // 解质押锁定区块数
}
```

### User 结构
```solidity
struct User {
    uint256 stAmount;           // 用户质押代币数量
    uint256 finishedMetaNode;   // 已分配的 MetaNode 数量
    uint256 pendingMetaNode;    // 待领取的 MetaNode 数量
    UnstakeRequest[] requests;  // 解质押请求列表
}
```

## 📊 Supabase 数据库设计

### 表结构设计

#### 1. users 表 - 用户信息
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_address TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE,
    preferences JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{}'
);
```

#### 2. stake_transactions 表 - 质押交易记录
```sql
CREATE TABLE stake_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    wallet_address TEXT NOT NULL,
    pool_id INTEGER NOT NULL,
    transaction_type TEXT NOT NULL, -- 'stake', 'unstake', 'claim', 'withdraw'
    amount DECIMAL(36, 18),
    tx_hash TEXT UNIQUE NOT NULL,
    block_number BIGINT,
    gas_used BIGINT,
    gas_price DECIMAL(36, 18),
    status TEXT DEFAULT 'pending', -- 'pending', 'confirmed', 'failed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed_at TIMESTAMP WITH TIME ZONE
);
```

#### 3. pool_stats 表 - 池子统计数据
```sql
CREATE TABLE pool_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id INTEGER NOT NULL,
    total_staked DECIMAL(36, 18) NOT NULL,
    total_rewards_distributed DECIMAL(36, 18) NOT NULL,
    active_users_count INTEGER DEFAULT 0,
    apy DECIMAL(10, 4),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. user_pool_positions 表 - 用户池子持仓
```sql
CREATE TABLE user_pool_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    wallet_address TEXT NOT NULL,
    pool_id INTEGER NOT NULL,
    staked_amount DECIMAL(36, 18) NOT NULL,
    pending_rewards DECIMAL(36, 18) DEFAULT 0,
    total_claimed_rewards DECIMAL(36, 18) DEFAULT 0,
    first_stake_at TIMESTAMP WITH TIME ZONE,
    last_action_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(wallet_address, pool_id)
);
```

#### 5. reward_history 表 - 奖励历史
```sql
CREATE TABLE reward_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    wallet_address TEXT NOT NULL,
    pool_id INTEGER NOT NULL,
    reward_amount DECIMAL(36, 18) NOT NULL,
    tx_hash TEXT NOT NULL,
    block_number BIGINT,
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 数据库索引优化
```sql
-- 性能优化索引
CREATE INDEX idx_stake_transactions_wallet ON stake_transactions(wallet_address);
CREATE INDEX idx_stake_transactions_pool ON stake_transactions(pool_id);
CREATE INDEX idx_stake_transactions_type ON stake_transactions(transaction_type);
CREATE INDEX idx_stake_transactions_status ON stake_transactions(status);
CREATE INDEX idx_pool_stats_pool_time ON pool_stats(pool_id, recorded_at);
CREATE INDEX idx_user_positions_wallet ON user_pool_positions(wallet_address);
CREATE INDEX idx_reward_history_wallet ON reward_history(wallet_address);
```

### 实时数据同步策略

#### 1. 事件监听器
```javascript
// 监听合约事件并同步到 Supabase
const syncContractEvents = async () => {
    contract.on('Staked', async (user, poolId, amount, event) => {
        await supabase.from('stake_transactions').insert({
            wallet_address: user,
            pool_id: poolId,
            transaction_type: 'stake',
            amount: ethers.utils.formatEther(amount),
            tx_hash: event.transactionHash,
            block_number: event.blockNumber,
            status: 'confirmed'
        });
    });
};
```

#### 2. 定时数据同步
```javascript
// 定时更新池子统计数据
const updatePoolStats = async () => {
    for (let poolId = 0; poolId < poolCount; poolId++) {
        const poolInfo = await contract.getPoolInfo(poolId);
        await supabase.from('pool_stats').insert({
            pool_id: poolId,
            total_staked: ethers.utils.formatEther(poolInfo.stTokenAmount),
            // ... 其他统计数据
        });
    }
};
```

## 🔧 主要合约接口

### 用户操作
- `stake(uint256 _pid, uint256 _amount)` - 质押代币
- `unstake(uint256 _pid, uint256 _amount)` - 申请解除质押
- `claimReward(uint256 _pid)` - 领取奖励
- `withdraw(uint256 _pid, uint256 _requestIndex)` - 提取解质押的代币

### 管理员操作
- `addPool(address _stTokenAddress, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks)` - 添加质押池
- `updatePool(uint256 _pid, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks)` - 更新质押池
- `pause()` / `unpause()` - 暂停/恢复合约

### 查询接口
- `getPoolInfo(uint256 _pid)` - 获取池信息
- `getUserInfo(uint256 _pid, address _user)` - 获取用户信息
- `pendingReward(uint256 _pid, address _user)` - 查询待领取奖励

## 🛠️ 开发环境设置

### 前置要求
- Node.js >= 16.0.0
- npm 或 yarn
- Hardhat 或 Foundry
- Supabase 账户

### 1. 安装依赖
```bash
npm install
# 或
yarn install

# 安装 Supabase 相关依赖
npm install @supabase/supabase-js
npm install --save-dev @types/node
```

### 2. Supabase 项目设置

#### 创建 Supabase 项目
1. 访问 [Supabase](https://supabase.com)
2. 创建新项目
3. 获取项目 URL 和 API Key

#### 环境变量配置
创建 `.env` 文件：
```bash
# 区块链网络配置
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your-project-id
PRIVATE_KEY=your-private-key

# Supabase 配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# 合约地址 (部署后更新)
STAKE_CONTRACT_ADDRESS=
METANODE_TOKEN_ADDRESS=
```

#### 数据库初始化
```bash
# 运行数据库迁移脚本
npm run db:migrate

# 或手动执行 SQL 脚本
psql -h db.your-project.supabase.co -U postgres -d postgres -f scripts/init-db.sql
```

### 3. Supabase 客户端配置
创建 `lib/supabase.js`：
```javascript
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseKey);

// 服务端使用 (具有完整权限)
export const supabaseAdmin = createClient(
  supabaseUrl, 
  process.env.SUPABASE_SERVICE_ROLE_KEY
);
```

### 编译合约
```bash
npx hardhat compile
# 或使用 Foundry
forge build
```

## 🧪 测试

### 测试环境准备
```bash
# 安装测试依赖
npm install --save-dev @nomicfoundation/hardhat-chai-matchers
npm install --save-dev @nomicfoundation/hardhat-network-helpers

# 编译合约
npx hardhat compile
```

### 运行测试套件
```bash
# 运行所有测试
npx hardhat test

# 运行特定测试文件
npx hardhat test test/StakeContract.test.js

# 运行特定测试用例
npx hardhat test --grep "should stake tokens correctly"

# 详细输出模式
npx hardhat test --verbose
```

### 测试覆盖率
```bash
# 生成覆盖率报告
npx hardhat coverage

# 查看覆盖率报告
open coverage/index.html
```

### Gas 使用分析
```bash
# 运行 Gas 报告
REPORT_GAS=true npx hardhat test

# 详细 Gas 分析
npx hardhat test --gas-reporter
```

### 集成测试
```bash
# 运行集成测试
npx hardhat test test/integration/

# 端到端测试
npm run test:e2e
```

### 测试脚本
```json
{
  "scripts": {
    "test": "hardhat test",
    "test:coverage": "hardhat coverage",
    "test:gas": "REPORT_GAS=true hardhat test",
    "test:integration": "hardhat test test/integration/",
    "test:unit": "hardhat test test/unit/",
    "test:watch": "hardhat test --watch"
  }
}
```



## 🚀 部署

### 1. 数据库部署 (Supabase)

#### 生产环境数据库设置
```bash
# 1. 在 Supabase 控制台创建生产项目
# 2. 执行数据库迁移
npm run db:migrate:prod

# 3. 设置行级安全策略 (RLS)
npm run db:setup-rls
```

#### 数据库安全策略
```sql
-- 启用行级安全
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE stake_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_pool_positions ENABLE ROW LEVEL SECURITY;

-- 用户只能访问自己的数据
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (wallet_address = current_setting('app.current_user'));

CREATE POLICY "Users can view own transactions" ON stake_transactions
  FOR SELECT USING (wallet_address = current_setting('app.current_user'));
```

### 2. 智能合约部署

#### 本地部署
```bash
npx hardhat run scripts/deploy.js --network localhost
```

#### Sepolia 测试网部署
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

#### 主网部署
```bash
npx hardhat run scripts/deploy.js --network mainnet
```

### 3. 部署配置

#### Hardhat 网络配置
在 `hardhat.config.js` 中配置网络参数：
```javascript
networks: {
  sepolia: {
    url: process.env.SEPOLIA_RPC_URL,
    accounts: [process.env.PRIVATE_KEY]
  },
  mainnet: {
    url: process.env.MAINNET_RPC_URL,
    accounts: [process.env.PRIVATE_KEY]
  }
}
```

### 4. 数据同步服务部署

#### 创建同步服务
创建 `services/sync-service.js`：
```javascript
const { ethers } = require('ethers');
const { supabaseAdmin } = require('../lib/supabase');

class SyncService {
  constructor() {
    this.provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
    this.contract = new ethers.Contract(
      process.env.STAKE_CONTRACT_ADDRESS,
      contractABI,
      this.provider
    );
  }

  async startEventSync() {
    // 监听合约事件
    this.contract.on('Staked', this.handleStakeEvent.bind(this));
    this.contract.on('Unstaked', this.handleUnstakeEvent.bind(this));
    this.contract.on('RewardClaimed', this.handleClaimEvent.bind(this));
  }

  async handleStakeEvent(user, poolId, amount, event) {
    await supabaseAdmin.from('stake_transactions').insert({
      wallet_address: user,
      pool_id: poolId.toNumber(),
      transaction_type: 'stake',
      amount: ethers.utils.formatEther(amount),
      tx_hash: event.transactionHash,
      block_number: event.blockNumber,
      status: 'confirmed'
    });
  }
}

module.exports = SyncService;
```

#### 部署到 Vercel/Railway
```bash
# 使用 Vercel 部署同步服务
vercel --prod

# 或使用 Railway
railway deploy
```

#### 环境变量配置 (生产环境)
```bash
# Vercel 环境变量
vercel env add SUPABASE_URL
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add STAKE_CONTRACT_ADDRESS
vercel env add RPC_URL

# Railway 环境变量
railway variables set SUPABASE_URL=your-url
railway variables set SUPABASE_SERVICE_ROLE_KEY=your-key
```

## 🔒 安全考虑

### 智能合约安全
1. **重入攻击防护**: 使用 ReentrancyGuard
2. **权限控制**: 基于 AccessControl 的角色管理
3. **暂停机制**: 紧急情况下可暂停合约操作
4. **输入验证**: 严格的参数验证和边界检查
5. **锁定期机制**: 防止快速进出攻击

### 数据库安全 (Supabase)
1. **行级安全策略 (RLS)**: 确保用户只能访问自己的数据
2. **API 密钥管理**: 区分匿名密钥和服务角色密钥的使用场景
3. **数据加密**: 敏感数据在传输和存储时加密
4. **访问控制**: 基于钱包地址的身份验证
5. **审计日志**: 记录所有数据库操作用于安全审计

### 数据同步安全
1. **事件验证**: 验证区块链事件的真实性
2. **重复处理防护**: 防止同一事件被重复处理
3. **数据一致性**: 确保链上链下数据的一致性
4. **错误处理**: 完善的错误处理和重试机制

### 环境变量安全
```bash
# 生产环境安全配置
NODE_ENV=production
SUPABASE_SERVICE_ROLE_KEY=*** # 仅服务端使用
PRIVATE_KEY=*** # 加密存储
RPC_URL=*** # 使用可信的 RPC 提供商
```

## 🔍 审计建议

### 智能合约审计
1. **奖励计算逻辑**: 重点关注奖励计算的准确性和溢出保护
2. **解质押锁定期**: 验证锁定期机制的正确实现
3. **权限控制**: 检查 AccessControl 的完整性和角色分配
4. **边界条件**: 测试极端情况和异常输入
5. **升级机制**: 验证合约升级的安全性和向后兼容性

### 数据库审计
1. **数据一致性**: 验证链上链下数据的一致性
2. **RLS 策略**: 检查行级安全策略的正确性
3. **API 安全**: 验证 Supabase API 的访问控制
4. **数据备份**: 确保数据备份和恢复机制
5. **性能优化**: 检查数据库查询性能和索引优化

### 系统集成审计
1. **事件同步**: 验证区块链事件监听和处理的可靠性
2. **错误处理**: 检查系统异常情况的处理机制
3. **监控告警**: 验证系统监控和告警机制
4. **负载测试**: 进行高并发场景下的压力测试
5. **灾难恢复**: 测试系统故障恢复能力

## 📄 许可证

MIT License

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📞 联系方式

如有问题或建议，请通过 GitHub Issues 联系我们。