# SHIB 风格 Meme 代币合约

## 项目介绍

基于以太坊区块链平台，使用 Solidity 智能合约开发语言，实现一个 SHIB 风格的 Meme 代币合约。该项目旨在创建一个功能完整的代币生态系统，包含代币税收机制、流动性池集成和交易限制功能。

## 核心功能

- **代币税功能**：实现交易税机制，对每笔代币交易征收一定比例的税费，并将税费分配给特定的地址或用于特定的用途
- **流动性池集成**：设计并实现与流动性池的交互功能，支持用户向流动性池添加和移除流动性
- **交易限制功能**：设置合理的交易限制，如单笔交易最大额度、每日交易次数限制等，防止恶意操纵市场

## 技术栈

### 区块链技术

- **区块链平台**: Ethereum
- **智能合约语言**: Solidity ^0.8.0
- **代币标准**: ERC-20

### 开发工具

- **开发框架**: Hardhat v2.19.5
- **测试框架**: Waffle + Chai
- **以太坊库**: Ethers.js v5.7.2
- **代码覆盖率**: Solidity Coverage
- **Gas 优化**: Hardhat Gas Reporter
- **合约验证**: Hardhat Etherscan

### 依赖库

- **OpenZeppelin**: v4.9.5 安全的智能合约库
- **Uniswap V2**: DEX 集成和流动性池
- **Ethers.js**: 以太坊交互库

### 开发环境

- **Node.js**: >= 16.0.0
- **npm**: >= 8.0.0
- **Git**: 版本控制

## 项目结构

```
shib-meme-token/
├── README.md                    # 项目说明文档
├── 理论梳理.md                   # 理论知识梳理
├── package.json                 # 项目依赖配置
├── hardhat.config.js           # Hardhat 配置文件
├── .env.example                # 环境变量示例
├── .gitignore                  # Git 忽略文件
├── contracts/                  # 智能合约目录
│   ├── ShibMemeToken.sol       # 主代币合约
│   ├── interfaces/             # 接口定义
│   │   ├── IERC20Extended.sol  # 扩展ERC20接口
│   │   └── IUniswapV2.sol      # Uniswap接口
│   ├── libraries/              # 库文件
│   │   └── TransferHelper.sol  # 转账助手
│   └── utils/                  # 工具合约
│       ├── Ownable.sol         # 所有权管理
│       └── ReentrancyGuard.sol # 重入攻击防护
├── test/                       # 测试文件目录
│   ├── ShibMemeToken.test.js   # 主合约测试
│   ├── TaxMechanism.test.js    # 税收机制测试
│   ├── LiquidityPool.test.js   # 流动性池测试
│   └── TradingLimits.test.js   # 交易限制测试
├── scripts/                    # 部署和工具脚本
│   ├── deploy.js               # 部署脚本
│   ├── verify.js               # 合约验证脚本
│   └── setup-liquidity.js     # 流动性设置脚本
├── docs/                       # 文档目录
│   ├── architecture.md         # 架构设计文档
│   ├── security.md             # 安全分析文档
│   └── api.md                  # API 文档
├── artifacts/                  # 编译产物（自动生成）
│   └── contracts/
└── cache/                      # Hardhat 缓存（自动生成）
```

## 环境要求

- Node.js >= 16.0.0
- npm >= 8.0.0
- Git
- MetaMask 钱包（用于测试）

## 安装指南

### 1. 克隆项目

```bash
git clone <repository-url>
cd shib-meme-token
```

### 2. 安装依赖

```bash
npm install
```

### 3. 环境配置

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，填入必要的配置
# PRIVATE_KEY=你的私钥
# INFURA_PROJECT_ID=你的Infura项目ID
# ETHERSCAN_API_KEY=你的Etherscan API密钥
```

## 操作指南

### 开发环境设置

#### 1. 编译合约

```bash
npm run compile
```

#### 2. 运行测试

```bash
# 运行所有测试
npm run test

# 运行特定测试文件
npx hardhat test test/ShibMemeToken.test.js

# 生成测试覆盖率报告
npm run coverage
```

#### 3. 本地网络部署

```bash
# 启动本地Hardhat网络
npm run node

# 在新终端中部署合约到本地网络
npm run deploy:localhost
```

### 测试网部署

#### 1. Goerli 测试网部署

```bash
npm run deploy:goerli
```

#### 2. 验证合约

```bash
npm run verify
```

### 主网部署

#### 1. 部署到以太坊主网

```bash
npm run deploy:mainnet
```

#### 2. 设置流动性池

```bash
npx hardhat run scripts/setup-liquidity.js --network mainnet
```

## 合约功能说明

### 代币基本信息

- **名称**: SHIB Meme Token
- **符号**: SMT
- **精度**: 18
- **总供应量**: 1,000,000,000 SMT

### 税收机制

- **买入税**: 3%（可配置）
- **卖出税**: 5%（可配置）
- **税收分配**:
  - 50% 用于流动性
  - 30% 用于营销钱包
  - 20% 用于开发团队

### 交易限制

- **最大交易额度**: 总供应量的 1%
- **最大持有量**: 总供应量的 2%
- **冷却时间**: 买卖之间 30 秒间隔

## 安全特性

- **重入攻击防护**: 使用 ReentrancyGuard
- **整数溢出防护**: Solidity 0.8+ 内置溢出检查
- **权限控制**: 基于 Ownable 的管理员权限
- **暂停机制**: 紧急情况下可暂停交易
- **黑名单功能**: 可将恶意地址加入黑名单

## 测试策略

- **单元测试**: 覆盖所有合约函数
- **集成测试**: 测试合约间交互
- **Gas 优化测试**: 确保交易成本合理
- **安全测试**: 防范常见攻击向量

## 部署清单

- [ ] 合约编译无错误
- [ ] 所有测试通过
- [ ] Gas 使用量在合理范围内
- [ ] 安全审计完成
- [ ] 环境变量配置正确
- [ ] 部署脚本测试完成
- [ ] 合约验证成功

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 联系方式

- 项目维护者: [Your Name]
- 邮箱: [your.email@example.com]
- 项目链接: [https://github.com/yourusername/shib-meme-token](https://github.com/yourusername/shib-meme-token)

## 免责声明

本项目仅用于学习和研究目的。在实际部署和使用前，请确保进行充分的安全审计。投资有风险，请谨慎决策。
