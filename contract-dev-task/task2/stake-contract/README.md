# MetaNode Stake Contract

## 项目概述

MetaNode Stake 是一个基于以太坊区块链的去中心化质押系统智能合约。该系统支持多种代币的质押，并基于用户质押的代币数量和时间长度分配 MetaNode 代币作为奖励。系统提供多个质押池，每个池可以独立配置质押代币、奖励计算等参数。

## 核心功能

### 🔒 质押功能
- 支持多种代币质押（Native Currency 和 ERC20 代币）
- 灵活的质押池配置
- 最小质押金额限制
- 实时奖励计算

### 💰 奖励机制
- 基于质押数量和时间的奖励分配
- MetaNode 代币作为奖励
- 可领取的待分配奖励追踪

### 🔓 解除质押
- 灵活的解除质押机制
- 可配置的锁定期
- 分批解除质押支持

### 🛡️ 安全特性
- 基于角色的访问控制
- 重入攻击保护
- 输入验证和异常处理
- 合约升级和暂停机制

## 技术栈

### 区块链技术
- **Solidity**: ^0.8.0 - 智能合约开发语言
- **Ethereum**: 目标部署网络
- **OpenZeppelin**: 安全的智能合约库
  - AccessControl - 角色权限管理
  - ReentrancyGuard - 重入攻击保护
  - Pausable - 合约暂停功能
  - Upgradeable - 合约升级支持

### 开发工具
- **Hardhat**: ^2.19.0 - 以太坊开发环境
  - 本地区块链网络
  - 智能合约编译和部署
  - 插件生态系统支持
  - TypeScript 支持
- **Ethers.js**: ^6.7.0 - 以太坊交互库
- **Waffle**: 智能合约测试框架
- **Solhint**: Solidity 代码检查工具

### 测试网络
- **Sepolia**: 测试网络部署

## 项目结构

```
stake-contract/
├── contracts/                 # 智能合约源码
│   ├── MetaNodeStake.sol     # 主质押合约
│   ├── interfaces/           # 合约接口
│   └── libraries/            # 工具库
├── scripts/                  # 部署和管理脚本
│   ├── deploy.js            # 部署脚本
│   └── setup.js             # 初始化脚本
├── test/                     # 测试文件
│   ├── MetaNodeStake.test.js # 主合约测试
│   └── helpers/             # 测试辅助工具
├── hardhat.config.js        # Hardhat 配置
├── package.json             # 项目依赖
├── .env.example             # 环境变量示例
├── Stake需求文档.md          # 需求文档
└── README.md                # 项目说明
```

## 数据结构

### Pool 结构
```solidity
struct Pool {
    address stTokenAddress;      // 质押代币地址
    uint256 poolWeight;          // 池权重
    uint256 lastRewardBlock;     // 最后奖励区块
    uint256 accMetaNodePerST;    // 累积奖励
    uint256 stTokenAmount;       // 总质押量
    uint256 minDepositAmount;    // 最小质押金额
    uint256 unstakeLockedBlocks; // 解锁区块数
}
```

### User 结构
```solidity
struct User {
    uint256 stAmount;           // 质押数量
    uint256 finishedMetaNode;   // 已分配奖励
    uint256 pendingMetaNode;    // 待领取奖励
    UnstakeRequest[] requests;  // 解质押请求
}
```

## 安装和设置

### 环境要求
- Node.js >= 16.0.0
- npm 或 yarn
- Git

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd stake-contract
```

2. **安装依赖**
```bash
npm install
```

3. **环境配置**
```bash
cp .env.example .env
# 编辑 .env 文件，填入必要的配置
```

4. **编译合约**
```bash
npx hardhat compile
```

5. **运行测试**
```bash
npx hardhat test
```

## 部署指南

### 本地部署
```bash
# 启动本地节点
npx hardhat node

# 部署到本地网络
npx hardhat run scripts/deploy.js --network localhost
```

### Sepolia 测试网部署
```bash
# 部署到 Sepolia 测试网
npx hardhat run scripts/deploy.js --network sepolia
```

### 环境变量配置
```env
PRIVATE_KEY=your_private_key
INFURA_API_KEY=your_infura_key
ETHERSCAN_API_KEY=your_etherscan_key
```

## 使用说明

### 主要接口

#### 质押操作
```solidity
function stake(uint256 _pid, uint256 _amount) external
```

#### 解除质押
```solidity
function unstake(uint256 _pid, uint256 _amount) external
```

#### 领取奖励
```solidity
function claimReward(uint256 _pid) external
```

#### 添加质押池（管理员）
```solidity
function addPool(
    address _stTokenAddress,
    uint256 _poolWeight,
    uint256 _minDepositAmount,
    uint256 _unstakeLockedBlocks
) external onlyRole(ADMIN_ROLE)
```

### 事件监听

合约会发出以下关键事件：
- `Staked(user, pid, amount)` - 质押事件
- `Unstaked(user, pid, amount)` - 解除质押事件
- `RewardClaimed(user, pid, amount)` - 奖励领取事件
- `PoolAdded(pid, stTokenAddress)` - 池添加事件

## 测试

### 运行所有测试
```bash
npm test
```

### 运行特定测试
```bash
npx hardhat test test/MetaNodeStake.test.js
```

### 测试覆盖率
```bash
npm run coverage
```

## 安全考虑

1. **访问控制**: 使用 OpenZeppelin 的 AccessControl 进行权限管理
2. **重入保护**: 所有外部调用都使用 ReentrancyGuard 保护
3. **输入验证**: 严格验证所有用户输入
4. **整数溢出**: 使用 Solidity 0.8+ 的内置溢出保护
5. **合约升级**: 支持安全的合约升级机制

## 开发指南

### 代码规范
- 遵循 Solidity 官方风格指南
- 使用 Solhint 进行代码检查
- 所有函数都需要完整的 NatSpec 注释

### 提交规范
- 所有代码变更必须通过测试
- 提交前运行代码检查
- 遵循语义化版本控制

## 许可证

MIT License

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交变更
4. 推送到分支
5. 创建 Pull Request

## 联系方式

如有问题或建议，请通过以下方式联系：
- 创建 Issue
- 发送邮件至项目维护者

---

**注意**: 这是一个智能合约项目，涉及资金安全。在主网部署前，请确保进行充分的测试和安全审计。