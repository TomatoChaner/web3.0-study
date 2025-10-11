# Substrate 自定义区块链项目

## 项目概述

运用 Substrate 开发框架，构建一个自定义区块链 Runtime。该 Runtime 需具备基本的账户管理、交易处理和区块生成功能。
基于 Pallet 设计模式，添加至少一个自定义功能模块，如投票模块或资产登记模块。
编写详细的项目文档，包括项目架构、功能说明、代码结构以及部署和运行步骤。

## 技术栈

### 核心框架
- **Substrate**: 区块链开发框架，提供模块化的区块链构建工具
- **FRAME**: Framework for Runtime Aggregation of Modularized Entities，Substrate 的核心开发框架
- **Polkadot SDK**: 包含 Substrate、Cumulus 和 Polkadot 的完整开发工具包

### 开发语言
- **Rust**: 主要开发语言，提供内存安全和高性能
- **WebAssembly (WASM)**: Runtime 编译目标，支持无分叉升级

### 核心依赖库
- **sp-core**: Substrate 核心原语和类型定义
- **sp-runtime**: Runtime 相关的核心类型和特征
- **frame-support**: FRAME 开发支持库，提供宏和工具
- **frame-system**: 系统级 Pallet，提供基础功能
- **pallet-balances**: 账户余额管理 Pallet
- **pallet-transaction-payment**: 交易费用处理 Pallet
- **pallet-sudo**: 超级用户权限管理 Pallet

### 开发工具
- **Cargo**: Rust 包管理器和构建工具
- **substrate-node-template**: 项目模板
- **polkadot-js**: 前端交互工具和 API

## 项目架构

### 整体架构
```
Substrate Node
├── Runtime (WASM)
│   ├── System Pallets
│   └── Custom Pallets
├── Node (Native)
│   ├── Network Layer
│   ├── Consensus Engine
│   └── RPC Interface
└── Client
    ├── Database
    └── Transaction Pool
```

### 核心组件

#### 1. Runtime 层
- **职责**: 定义区块链的业务逻辑和状态转换规则
- **组成**: 由多个 Pallet 模块组合而成
- **特点**: 编译为 WASM，支持无分叉升级

#### 2. Node 层
- **职责**: 处理网络通信、共识机制和数据存储
- **组成**: P2P 网络、共识引擎、RPC 服务
- **特点**: 原生代码执行，提供高性能

#### 3. Client 层
- **职责**: 状态存储、交易池管理、区块同步
- **组成**: 数据库接口、内存池、同步服务
- **特点**: 抽象化存储和网络操作

## 项目结构

```
substrate-custom-chain/
├── Cargo.toml                 # 工作空间配置
├── README.md                  # 项目文档
├── node/                      # 节点实现
│   ├── Cargo.toml
│   ├── src/
│   │   ├── main.rs           # 节点入口点
│   │   ├── chain_spec.rs     # 链规格定义
│   │   ├── service.rs        # 节点服务配置
│   │   ├── rpc.rs           # RPC 接口定义
│   │   └── cli.rs           # 命令行接口
│   └── build.rs             # 构建脚本
├── runtime/                   # Runtime 实现
│   ├── Cargo.toml
│   ├── src/
│   │   ├── lib.rs           # Runtime 主文件
│   │   └── weights.rs       # 权重配置
│   └── build.rs             # WASM 构建脚本
├── pallets/                   # 自定义 Pallet 模块
│   ├── voting/               # 投票模块
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs       # 投票逻辑实现
│   │       ├── mock.rs      # 测试模拟环境
│   │       └── tests.rs     # 单元测试
│   └── asset-registry/       # 资产登记模块
│       ├── Cargo.toml
│       └── src/
│           ├── lib.rs       # 资产登记逻辑
│           ├── mock.rs      # 测试模拟环境
│           └── tests.rs     # 单元测试
├── scripts/                   # 部署和工具脚本
│   ├── init.sh              # 初始化脚本
│   ├── build.sh             # 构建脚本
│   └── docker/              # Docker 配置
│       ├── Dockerfile
│       └── docker-compose.yml
└── docs/                     # 详细文档
    ├── architecture.md      # 架构说明
    ├── pallets.md          # Pallet 文档
    └── deployment.md       # 部署指南
```

## 功能模块说明

### 系统 Pallets

#### 1. System Pallet
- **功能**: 提供基础系统功能
- **职责**: 区块号管理、事件系统、存储根管理
- **接口**: 系统级调用和查询

#### 2. Balances Pallet
- **功能**: 账户余额管理
- **职责**: 转账、余额查询、存在性押金
- **特性**: 支持预留余额和锁定余额

#### 3. Transaction Payment Pallet
- **功能**: 交易费用处理
- **职责**: 费用计算、费用扣除、小费处理
- **机制**: 基于权重的费用模型

### 自定义 Pallets

#### 1. 投票模块 (Voting Pallet)

**核心功能**:
- 提案创建和管理
- 投票权重计算
- 投票期限控制
- 结果统计和执行

**存储结构**:
```rust
// 提案信息
pub struct Proposal {
    pub title: Vec<u8>,
    pub description: Vec<u8>,
    pub proposer: AccountId,
    pub voting_end: BlockNumber,
    pub threshold: Permill,
}

// 投票记录
pub struct Vote {
    pub voter: AccountId,
    pub proposal_id: ProposalId,
    pub approve: bool,
    pub weight: Balance,
}
```

**主要接口**:
- `create_proposal()`: 创建提案
- `vote()`: 投票
- `close_proposal()`: 关闭提案并执行结果
- `get_proposal_status()`: 查询提案状态

#### 2. 资产登记模块 (Asset Registry Pallet)

**核心功能**:
- 数字资产注册
- 资产元数据管理
- 所有权转移
- 资产查询和验证

**存储结构**:
```rust
// 资产信息
pub struct AssetInfo {
    pub name: Vec<u8>,
    pub symbol: Vec<u8>,
    pub decimals: u8,
    pub total_supply: Balance,
    pub owner: AccountId,
    pub metadata: Vec<u8>,
}

// 资产余额
pub struct AssetBalance {
    pub asset_id: AssetId,
    pub account: AccountId,
    pub balance: Balance,
}
```

**主要接口**:
- `register_asset()`: 注册新资产
- `transfer_ownership()`: 转移资产所有权
- `update_metadata()`: 更新资产元数据
- `get_asset_info()`: 查询资产信息

## 部署方案

### 开发环境搭建

#### 1. 系统要求
- **操作系统**: Linux, macOS, Windows (WSL2)
- **内存**: 最少 8GB RAM，推荐 16GB+
- **存储**: 至少 50GB 可用空间
- **网络**: 稳定的互联网连接

#### 2. 依赖安装

**安装 Rust 工具链**:
```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 安装 nightly 工具链
rustup install nightly
rustup target add wasm32-unknown-unknown --toolchain nightly
```

**安装系统依赖**:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y git clang curl libssl-dev llvm libudev-dev make protobuf-compiler

# macOS
brew install openssl cmake llvm
```

#### 3. 项目初始化

**克隆项目模板**:
```bash
# 使用 Substrate 节点模板
git clone https://github.com/substrate-developer-hub/substrate-node-template
cd substrate-node-template

# 或创建新项目
cargo install --git https://github.com/substrate-developer-hub/substrate-node-template substrate-node-template
substrate-node-template --authors "Your Name" --description "Custom Blockchain" --git-remote origin my-custom-chain
```

### 编译构建

#### 1. 开发模式构建
```bash
# 快速构建（开发用）
cargo build --release

# 检查代码
cargo check

# 运行测试
cargo test
```

#### 2. 生产模式构建
```bash
# 优化构建
cargo build --release --features runtime-benchmarks

# 构建 WASM Runtime
cargo build --release -p node-template-runtime
```

#### 3. Docker 构建
```bash
# 构建 Docker 镜像
docker build -t my-substrate-node .

# 运行容器
docker run -p 9944:9944 -p 9933:9933 my-substrate-node --dev --ws-external
```

### 网络部署

#### 1. 单节点开发网络
```bash
# 启动开发节点
./target/release/node-template --dev --tmp

# 指定数据目录
./target/release/node-template --dev --base-path /tmp/alice
```

#### 2. 多节点测试网络

**启动第一个节点（Alice）**:
```bash
./target/release/node-template \
  --base-path /tmp/alice \
  --chain local \
  --alice \
  --port 30333 \
  --ws-port 9945 \
  --rpc-port 9933 \
  --node-key 0000000000000000000000000000000000000000000000000000000000000001 \
  --telemetry-url "wss://telemetry.polkadot.io/submit/ 0" \
  --validator
```

**启动第二个节点（Bob）**:
```bash
./target/release/node-template \
  --base-path /tmp/bob \
  --chain local \
  --bob \
  --port 30334 \
  --ws-port 9946 \
  --rpc-port 9934 \
  --telemetry-url "wss://telemetry.polkadot.io/submit/ 0" \
  --validator \
  --bootnodes /ip4/127.0.0.1/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp
```

#### 3. 生产环境部署

**系统服务配置**:
```bash
# 创建系统用户
sudo useradd --no-create-home --shell /bin/false substrate

# 创建服务文件
sudo tee /etc/systemd/system/substrate.service > /dev/null <<EOF
[Unit]
Description=Substrate Node
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=substrate
ExecStart=/usr/local/bin/node-template --chain mainnet --validator --name "MyNode"

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl enable substrate
sudo systemctl start substrate
```

**监控和日志**:
```bash
# 查看服务状态
sudo systemctl status substrate

# 查看日志
sudo journalctl -u substrate -f

# 性能监控
htop
iostat -x 1
```

### 前端集成

#### 1. Polkadot.js Apps
```bash
# 访问 Web 界面
# https://polkadot.js.org/apps/?rpc=ws://localhost:9944

# 或本地部署
git clone https://github.com/polkadot-js/apps
cd apps
yarn install
yarn start
```

#### 2. 自定义前端
```javascript
// 使用 Polkadot.js API
import { ApiPromise, WsProvider } from '@polkadot/api';

const wsProvider = new WsProvider('ws://localhost:9944');
const api = await ApiPromise.create({ provider: wsProvider });

// 查询链信息
const chain = await api.rpc.system.chain();
const version = await api.rpc.system.version();
console.log(`Connected to ${chain} v${version}`);
```

## 运行步骤

### 1. 快速启动
```bash
# 克隆项目
git clone <repository-url>
cd substrate-custom-chain

# 安装依赖并构建
cargo build --release

# 启动开发节点
./target/release/node-template --dev --tmp
```

### 2. 功能测试
```bash
# 运行单元测试
cargo test

# 运行集成测试
cargo test --features runtime-benchmarks

# 基准测试
cargo run --release --features runtime-benchmarks -- benchmark
```

### 3. 交互测试
- 访问 [Polkadot.js Apps](https://polkadot.js.org/apps/?rpc=ws://localhost:9944)
- 连接到本地节点
- 测试账户管理、转账等基础功能
- 测试自定义 Pallet 功能

## 注意事项

1. **安全性**: 生产环境中务必更改默认密钥和配置
2. **性能**: 根据实际需求调整节点配置和硬件规格
3. **升级**: 定期更新 Substrate 版本以获得最新功能和安全修复
4. **备份**: 定期备份节点数据和密钥文件
5. **监控**: 建立完善的监控和告警系统

## 相关资源

- [Substrate 官方文档](https://docs.substrate.io/)
- [Polkadot Wiki](https://wiki.polkadot.network/)
- [Substrate Recipes](https://substrate.dev/recipes/)
- [Polkadot.js API 文档](https://polkadot.js.org/docs/)
- [Substrate Stack Exchange](https://substrate.stackexchange.com/)
