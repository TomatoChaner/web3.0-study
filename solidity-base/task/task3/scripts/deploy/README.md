# 部署脚本说明

本目录包含了拍卖系统的完整部署脚本，按照模块化设计，可以单独部署各个合约或一次性部署所有合约。

## 脚本文件

### 1. 01-deploy-nft.ts
部署 AuctionNFT 合约
- 创建用于拍卖的 NFT 合约
- 设置基础 URI 和合约元数据
- 验证部署结果

### 2. 02-deploy-oracle.ts
部署 PriceOracle 合约
- 创建价格预言机合约
- 添加支持的代币价格源
- 初始化价格数据

### 3. 03-deploy-auction.ts
部署拍卖合约
- 部署基础 AuctionHouse 合约
- 部署可升级 AuctionHouseUpgradeable 合约
- 初始化合约配置

### 4. 04-deploy-factory.ts
部署工厂合约
- 部署 ProxyAdmin 合约
- 部署基础 AuctionFactory 合约
- 部署可升级 AuctionFactoryUpgradeable 合约
- 配置工厂参数和模板

### 5. deploy-all.ts
完整部署脚本
- 按顺序部署所有合约
- 处理合约间的依赖关系
- 生成部署摘要和配置文件

## 使用方法

### 单独部署合约
```bash
# 部署 NFT 合约
npx hardhat run scripts/deploy/01-deploy-nft.ts --network localhost

# 部署价格预言机
npx hardhat run scripts/deploy/02-deploy-oracle.ts --network localhost

# 部署拍卖合约
npx hardhat run scripts/deploy/03-deploy-auction.ts --network localhost

# 部署工厂合约
npx hardhat run scripts/deploy/04-deploy-factory.ts --network localhost
```

### 完整部署
```bash
# 一次性部署所有合约
npx hardhat run scripts/deploy/deploy-all.ts --network localhost
```

## 部署顺序

1. **AuctionNFT** - NFT 合约（独立部署）
2. **PriceOracle** - 价格预言机（独立部署）
3. **AuctionHouse** - 拍卖合约（依赖价格预言机）
4. **AuctionFactory** - 工厂合约（依赖价格预言机和拍卖模板）

## 部署结果

部署完成后，会在项目根目录生成 `deployments.json` 文件，包含：
- 网络信息
- 部署者地址
- 所有合约地址
- 部署时间戳
- Gas 消耗统计

## 注意事项

1. **网络配置**：确保 hardhat.config.ts 中配置了正确的网络参数
2. **账户余额**：确保部署账户有足够的 ETH 支付 Gas 费用
3. **合约验证**：部署到测试网或主网后，建议进行合约验证
4. **权限管理**：部署完成后，根据需要转移合约所有权

## 环境要求

- Node.js >= 16
- Hardhat
- 配置好的网络连接
- 足够的 ETH 余额用于部署