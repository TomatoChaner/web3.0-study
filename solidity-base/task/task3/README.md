# NFT 拍卖市场 (NFT Auction Marketplace)

基于 Hardhat 2.26.3 开发的去中心化 NFT 拍卖平台，集成 Chainlink 预言机和代理升级功能。

## 🎯 项目目标

1. **NFT 拍卖系统**：实现完整的 NFT 拍卖生命周期管理
2. **Chainlink 集成**：使用预言机获取实时价格数据，支持跨链功能
3. **代理升级**：采用 UUPS/透明代理模式实现合约安全升级
4. **工厂模式**：类似 Uniswap V2 的工厂模式管理拍卖实例

## 🏗️ 项目架构

### 核心合约结构

```
contracts/
├── interfaces/                     # 合约接口定义
│   ├── IERC721Mintable.sol         # NFT 铸造接口
│   ├── IAuction.sol                # 拍卖接口定义
│   ├── IAuctionFactory.sol         # 工厂接口
│   └── IPriceOracle.sol            # 预言机接口
├── nft/
│   └── AuctionNFT.sol              # ERC721 NFT 合约
├── auction/
│   ├── AuctionHouse.sol            # 核心拍卖逻辑合约
│   └── AuctionFactory.sol          # 拍卖工厂合约
├── proxy/
│   ├── AuctionHouseProxy.sol       # UUPS 代理合约
│   └── ProxyAdmin.sol              # 代理管理合约
└── oracle/
    ├── PriceOracle.sol             # Chainlink 价格预言机集成
    └── CCIPIntegration.sol         # 跨链功能集成
```

### 功能模块设计

#### 1. NFT 合约模块

- **AuctionNFT.sol**：基于 ERC721 标准的 NFT 合约
  - 支持 NFT 铸造和转移
  - 集成元数据管理
  - 权限控制和安全机制

#### 2. 拍卖系统模块

- **AuctionHouse.sol**：核心拍卖逻辑

  - 创建拍卖：NFT 上架拍卖
  - 出价管理：支持 ETH 和 ERC20 代币出价
  - 拍卖结算：自动转移 NFT 和资金
  - 手续费机制：动态手续费计算

- **AuctionFactory.sol**：工厂模式管理
  - 创建拍卖实例
  - 拍卖合约注册表
  - 统一配置管理

#### 3. 代理升级模块

- **UUPS 代理模式**：实现合约安全升级
  - 逻辑合约与存储分离
  - 升级权限控制
  - 版本管理机制

#### 4. 预言机集成模块

- **PriceOracle.sol**：价格数据获取

  - ETH/USD 价格获取
  - ERC20/USD 价格获取
  - 价格数据验证和缓存

- **CCIPIntegration.sol**：跨链功能
  - 跨链 NFT 拍卖
  - 跨链资金结算
  - 消息传递机制

## 📁 项目目录结构

```
├── contracts/                      # 智能合约源码
│   ├── interfaces/                 # 合约接口定义
│   ├── nft/                       # NFT 合约
│   ├── auction/                   # 拍卖合约
│   ├── proxy/                     # 代理合约
│   └── oracle/                    # 预言机合约
├── test/                          # 测试文件
│   ├── unit/                      # 单元测试
│   ├── integration/               # 集成测试
│   └── fixtures/                  # 测试数据
├── scripts/                       # 部署和管理脚本
│   ├── deploy/                    # 部署脚本
│   └── utils/                     # 工具脚本
├── ignition/modules/              # Hardhat Ignition 部署模块
├── hardhat.config.ts              # Hardhat 配置
├── package.json                   # 项目依赖
├── tsconfig.json                  # TypeScript 配置
├── README.md                      # 项目说明
├── 开发计划.md                     # 开发迭代计划
└── 项目需求.md                     # 项目需求文档
```

## 🔧 技术栈

- **框架**：Hardhat 2.26.3
- **语言**：Solidity ^0.8.19, TypeScript 5.9.2
- **标准**：ERC721, ERC20, EIP-1967 (代理)
- **库**：@nomicfoundation/hardhat-toolbox 6.1.0, OpenZeppelin Contracts, Chainlink Contracts
- **测试**：Mocha 10.x, Chai 4.5.0, Ethers.js 6.15.0
- **部署**：Hardhat Ignition 0.15.x, @nomicfoundation/hardhat-ethers 3.1.0

## 🚀 快速开始

### 环境要求

- Node.js >= 16.0.0
- npm >= 8.0.0

### 安装依赖

```bash
npm install
```

### 编译合约

```bash
npx hardhat compile
```

### 运行测试

```bash
npx hardhat test
```

### 部署到本地网络

```bash
npx hardhat node
npx hardhat run scripts/deploy/deploy-all.ts --network localhost
```

### 部署到测试网

#### 1. 配置网络参数

在 `hardhat.config.ts` 中配置测试网络：

```typescript
networks: {
  goerli: {
    url: process.env.GOERLI_URL || "",
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
  },
  sepolia: {
    url: process.env.SEPOLIA_URL || "",
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
  }
}
```

#### 2. 设置环境变量

创建 `.env` 文件：

```bash
GOERLI_URL=https://goerli.infura.io/v3/YOUR_INFURA_KEY
SEPOLIA_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=your_private_key_here
```

#### 3. 获取测试网 ETH

- Goerli: https://goerlifaucet.com/
- Sepolia: https://sepoliafaucet.com/

#### 4. 执行部署

```bash
# 部署到 Goerli 测试网
npx hardhat run scripts/deploy/deploy-all.ts --network goerli

# 部署到 Sepolia 测试网
npx hardhat run scripts/deploy/deploy-all.ts --network sepolia
```

## 📋 开发计划

### 第一阶段：基础设施搭建 ✅

- [x] 项目初始化和配置
- [x] 基础合约接口定义
- [x] 项目结构规划

### 第二阶段：核心 NFT 功能

- [ ] NFT 合约实现
- [ ] NFT 单元测试
- [ ] 权限控制和安全机制

### 第三阶段：拍卖核心逻辑

- [ ] 基础拍卖合约
- [ ] 拍卖生命周期管理
- [ ] 出价和结算机制

### 第四阶段：工厂模式实现

- [ ] 工厂合约开发
- [ ] 拍卖实例管理
- [ ] 集成测试

### 第五阶段：Chainlink 预言机集成

- [ ] 价格预言机实现
- [ ] 多币种出价支持
- [ ] 价格转换机制

### 第六阶段：代理升级功能

- [ ] UUPS 代理实现
- [ ] 升级权限控制
- [ ] 存储布局兼容性

### 第七阶段：跨链功能（高级）

- [ ] CCIP 跨链集成
- [ ] 跨链拍卖逻辑
- [ ] 跨链资金结算

### 第八阶段：部署和优化

- [ ] 完整测试套件
- [ ] 部署脚本开发
- [x] 测试网部署配置和文档
- [ ] 文档完善和安全审计

**总预计时间**：20-27 天

## 🔐 安全考虑

- **重入攻击防护**：使用 ReentrancyGuard
- **权限控制**：基于角色的访问控制
- **代理安全**：UUPS 模式升级保护
- **价格操纵防护**：多源价格验证
- **资金安全**：托管机制和紧急暂停

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**注意**：本项目仅用于学习和研究目的，请勿用于生产环境。
