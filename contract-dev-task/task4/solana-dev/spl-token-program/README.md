# SPL Token Program

一个基于Solana区块链的SPL代币发行和管理程序，提供完整的代币生命周期管理功能。

## 🚀 功能特性

- **代币发行**: 创建新的SPL代币
- **代币铸造**: 向指定地址铸造代币
- **代币转账**: 在地址间转移代币
- **代币销毁**: 销毁指定数量的代币
- **权限管理**: 管理铸造和冻结权限
- **余额查询**: 查询代币余额和信息
- **Web界面**: 直观的前端管理界面

## 📋 技术栈

- **区块链**: Solana
- **智能合约框架**: Anchor
- **编程语言**: Rust (合约), JavaScript/TypeScript (前端)
- **前端**: HTML5, CSS3 (Tailwind), Vanilla JavaScript
- **工具**: Node.js, Yarn, Docker

## 🛠️ 环境要求

- Node.js >= 16.0.0
- Rust >= 1.70.0
- Solana CLI >= 1.18.0
- Anchor CLI >= 0.32.0
- Yarn >= 1.22.0

## 📦 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd spl-token-program
```

### 2. 安装依赖

```bash
# 安装Node.js依赖
yarn install

# 安装Rust工具链（如果未安装）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安装Solana CLI（如果未安装）
sh -c "$(curl -sSfL https://release.solana.com/v1.18.0/install)"

# 安装Anchor（如果未安装）
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install latest
avm use latest
```

### 3. 配置环境

```bash
# 复制环境配置文件
cp .env.example .env

# 配置Solana为本地网络
solana config set --url localhost
```

### 4. 启动开发环境

```bash
# 启动Solana测试验证器
solana-test-validator --reset

# 在新终端中构建和部署程序
anchor build
anchor deploy

# 启动开发服务器
yarn dev
```

### 5. 访问应用

打开浏览器访问 `http://localhost:3000`

## 🔧 开发命令

### 基础命令

```bash
# 构建程序
yarn build

# 部署程序
yarn deploy

# 运行测试
yarn test

# 启动开发服务器
yarn dev

# 代码格式化
yarn lint:fix
```

### 代币管理命令

```bash
# 创建新代币
yarn token:create [小数位数]

# 查看代币信息
yarn token:info

# 铸造代币
yarn token:mint <接收地址> <数量>

# 转账代币
yarn token:transfer <发送地址> <接收地址> <数量>

# 销毁代币
yarn token:burn <拥有者地址> <数量>

# 查看余额
yarn token:balance <地址>
```

## 🏗️ 项目结构

```
spl-token-program/
├── app/                    # 前端应用
│   ├── index.html         # 主页面
│   └── app.js             # 前端逻辑
├── programs/              # Anchor程序
│   └── spl-token-program/
│       └── src/
│           └── lib.rs     # 主程序代码
├── scripts/               # 工具脚本
│   ├── deploy.js          # 部署脚本
│   ├── dev-server.js      # 开发服务器
│   └── token-manager.js   # 代币管理工具
├── tests/                 # 测试文件
│   └── spl-token-program.ts
├── Anchor.toml            # Anchor配置
├── Cargo.toml             # Rust依赖
├── package.json           # Node.js依赖
├── tsconfig.json          # TypeScript配置
├── Dockerfile             # Docker配置
├── docker-compose.yml     # Docker Compose配置
└── README.md              # 项目文档
```

## 🧪 测试

### 运行单元测试

```bash
# 运行所有测试
anchor test

# 运行特定测试
anchor test --skip-local-validator
```

### 手动测试流程

1. 启动本地验证器
2. 部署程序
3. 打开前端界面
4. 连接钱包
5. 创建代币
6. 测试各项功能

## 🚢 部署

### 本地部署

```bash
# 启动本地验证器
solana-test-validator --reset

# 部署程序
anchor deploy
```

### 开发网部署

```bash
# 切换到开发网
solana config set --url devnet

# 获取开发网SOL
solana airdrop 2

# 部署到开发网
anchor deploy --provider.cluster devnet
```

### Docker部署

```bash
# 构建Docker镜像
docker build -t spl-token-program .

# 运行容器
docker run -p 3000:3000 -p 8899:8899 spl-token-program

# 或使用Docker Compose
docker-compose up
```

## 📚 API文档

### 程序指令

#### `initialize_mint`
初始化新的代币铸造

**参数:**
- `decimals: u8` - 代币小数位数

#### `mint_tokens`
铸造代币到指定账户

**参数:**
- `amount: u64` - 铸造数量

#### `transfer_tokens`
转账代币

**参数:**
- `amount: u64` - 转账数量

#### `burn_tokens`
销毁代币

**参数:**
- `amount: u64` - 销毁数量

#### `update_mint_authority`
更新铸造权限

**参数:**
- `new_authority: Option<Pubkey>` - 新的权限地址

#### `get_token_info`
获取代币信息

**返回:**
- 代币总供应量
- 小数位数
- 权限信息

## 🔒 安全考虑

- **权限控制**: 只有授权用户可以铸造和管理代币
- **输入验证**: 所有输入都经过严格验证
- **溢出保护**: 防止数值溢出攻击
- **重入保护**: 防止重入攻击
- **访问控制**: 基于角色的访问控制

## 🐛 故障排除

### 常见问题

1. **构建失败**
   ```bash
   # 清理并重新构建
   anchor clean
   anchor build
   ```

2. **部署失败**
   ```bash
   # 检查网络配置
   solana config get
   
   # 检查余额
   solana balance
   ```

3. **测试失败**
   ```bash
   # 重置验证器
   solana-test-validator --reset
   ```

4. **前端连接失败**
   - 检查RPC端点配置
   - 确认验证器正在运行
   - 检查防火墙设置

### 日志查看

```bash
# 查看验证器日志
solana logs

# 查看程序日志
solana logs <PROGRAM_ID>
```

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🔗 相关链接

- [Solana官方文档](https://docs.solana.com/)
- [Anchor框架文档](https://www.anchor-lang.com/)
- [SPL Token文档](https://spl.solana.com/token)
- [Solana Web3.js文档](https://solana-labs.github.io/solana-web3.js/)

## 📞 支持

如有问题或建议，请：

1. 查看[FAQ](docs/FAQ.md)
2. 搜索[Issues](../../issues)
3. 创建新的Issue
4. 联系维护者

---

**注意**: 这是一个教育和开发用途的项目。在生产环境中使用前，请进行充分的安全审计。