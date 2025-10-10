# SHIB Meme Token API 文档

## 概述

本文档详细描述了 SHIB Meme Token 智能合约的所有公共接口、函数、事件和使用方法。

## 合约地址

- **主网**: `待部署`
- **测试网**: `待部署`
- **本地**: `通过部署脚本获取`

## 基本信息

### 代币信息
```solidity
function name() external view returns (string memory);
function symbol() external view returns (string memory);
function decimals() external view returns (uint8);
function totalSupply() external view returns (uint256);
```

**返回值:**
- `name`: "SHIB Meme Token"
- `symbol`: "SHIB"
- `decimals`: 18
- `totalSupply`: 1,000,000,000 * 10^18

## ERC-20 标准接口

### 余额查询
```solidity
function balanceOf(address account) external view returns (uint256);
```

**参数:**
- `account`: 查询地址

**返回值:**
- 该地址的代币余额

### 授权查询
```solidity
function allowance(address owner, address spender) external view returns (uint256);
```

**参数:**
- `owner`: 代币所有者地址
- `spender`: 被授权地址

**返回值:**
- 授权额度

### 转账
```solidity
function transfer(address to, uint256 amount) external returns (bool);
```

**参数:**
- `to`: 接收地址
- `amount`: 转账数量

**返回值:**
- 转账是否成功

**注意事项:**
- 会收取税收（如果适用）
- 受交易限制约束
- 检查黑名单状态

### 授权
```solidity
function approve(address spender, uint256 amount) external returns (bool);
```

**参数:**
- `spender`: 被授权地址
- `amount`: 授权数量

### 授权转账
```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool);
```

**参数:**
- `from`: 发送地址
- `to`: 接收地址
- `amount`: 转账数量

## 税收管理接口

### 查询税收信息
```solidity
function buyTax() external view returns (uint256);
function sellTax() external view returns (uint256);
function marketingTax() external view returns (uint256);
function developmentTax() external view returns (uint256);
function liquidityTax() external view returns (uint256);
```

**返回值:**
- 各类税收百分比（基数为100）

### 更新税收 (仅所有者)
```solidity
function updateBuyTax(uint256 newBuyTax) external onlyOwner;
function updateSellTax(uint256 newSellTax) external onlyOwner;
function updateTaxDistribution(
    uint256 newMarketingTax,
    uint256 newDevelopmentTax,
    uint256 newLiquidityTax
) external onlyOwner;
```

**参数:**
- `newBuyTax`: 新的买入税（0-25）
- `newSellTax`: 新的卖出税（0-25）
- `newMarketingTax`: 营销税分配比例
- `newDevelopmentTax`: 开发税分配比例
- `newLiquidityTax`: 流动性税分配比例

**限制:**
- 总税收不能超过25%
- 分配比例总和必须等于100

## 交易限制接口

### 查询限制信息
```solidity
function maxTxAmount() external view returns (uint256);
function maxWalletSize() external view returns (uint256);
function tradingEnabled() external view returns (bool);
```

### 更新限制 (仅所有者)
```solidity
function updateMaxTxAmount(uint256 newMaxTxAmount) external onlyOwner;
function updateMaxWalletSize(uint256 newMaxWalletSize) external onlyOwner;
function enableTrading() external onlyOwner;
```

**参数:**
- `newMaxTxAmount`: 新的最大交易额度
- `newMaxWalletSize`: 新的最大钱包持有量

**限制:**
- 最大交易额度不能低于总供应量的0.1%
- 最大钱包持有量不能低于总供应量的0.5%

## 黑名单管理接口

### 查询黑名单状态
```solidity
function isBlacklisted(address account) external view returns (bool);
```

### 管理黑名单 (仅所有者)
```solidity
function blacklistAddress(address account, bool blacklisted) external onlyOwner;
function blacklistMultipleAddresses(address[] calldata accounts, bool blacklisted) external onlyOwner;
```

**参数:**
- `account`: 目标地址
- `accounts`: 地址数组（最多100个）
- `blacklisted`: 是否加入黑名单

## 费用排除接口

### 查询排除状态
```solidity
function isExcludedFromFee(address account) external view returns (bool);
function isExcludedFromMaxTx(address account) external view returns (bool);
```

### 管理排除 (仅所有者)
```solidity
function excludeFromFee(address account, bool excluded) external onlyOwner;
function excludeFromMaxTx(address account, bool excluded) external onlyOwner;
```

## 钱包管理接口

### 查询钱包地址
```solidity
function marketingWallet() external view returns (address);
function developmentWallet() external view returns (address);
function liquidityWallet() external view returns (address);
```

### 更新钱包地址 (仅所有者)
```solidity
function updateMarketingWallet(address newMarketingWallet) external onlyOwner;
function updateDevelopmentWallet(address newDevelopmentWallet) external onlyOwner;
function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner;
```

## Uniswap 集成接口

### 查询 Uniswap 信息
```solidity
function uniswapV2Router() external view returns (address);
function uniswapV2Pair() external view returns (address);
function swapEnabled() external view returns (bool);
function swapTokensAtAmount() external view returns (uint256);
```

### 管理自动交换 (仅所有者)
```solidity
function setSwapEnabled(bool enabled) external onlyOwner;
function setSwapTokensAtAmount(uint256 amount) external onlyOwner;
```

## 紧急功能接口

### 暂停功能 (仅所有者)
```solidity
function pause() external onlyOwner;
function unpause() external onlyOwner;
function paused() external view returns (bool);
```

### 紧急提取 (仅所有者)
```solidity
function emergencyWithdrawETH() external onlyOwner;
function emergencyWithdrawToken(address token, uint256 amount) external onlyOwner;
```

### 手动操作 (仅所有者)
```solidity
function manualSwapAndDistribute() external onlyOwner;
```

## 事件

### ERC-20 事件
```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
```

### 税收事件
```solidity
event BuyTaxUpdated(uint256 oldTax, uint256 newTax);
event SellTaxUpdated(uint256 oldTax, uint256 newTax);
event TaxDistributionUpdated(uint256 marketing, uint256 development, uint256 liquidity);
```

### 限制事件
```solidity
event MaxTxAmountUpdated(uint256 oldAmount, uint256 newAmount);
event MaxWalletSizeUpdated(uint256 oldSize, uint256 newSize);
event TradingEnabled(uint256 timestamp);
```

### 黑名单事件
```solidity
event BlacklistUpdated(address indexed account, bool isBlacklisted);
```

### 排除事件
```solidity
event ExcludeFromFeeUpdated(address indexed account, bool excluded);
event ExcludeFromMaxTxUpdated(address indexed account, bool excluded);
```

### 钱包事件
```solidity
event MarketingWalletUpdated(address indexed oldWallet, address indexed newWallet);
event DevelopmentWalletUpdated(address indexed oldWallet, address indexed newWallet);
event LiquidityWalletUpdated(address indexed oldWallet, address indexed newWallet);
```

### 交换事件
```solidity
event SwapEnabledUpdated(bool enabled);
event SwapTokensAtAmountUpdated(uint256 oldAmount, uint256 newAmount);
event SwapAndDistribute(uint256 tokensSwapped, uint256 ethReceived);
```

### 紧急事件
```solidity
event EmergencyWithdraw(string tokenType, uint256 amount);
event ContractPaused(uint256 timestamp);
event ContractUnpaused(uint256 timestamp);
```

## 使用示例

### JavaScript (ethers.js)

#### 连接合约
```javascript
const { ethers } = require("ethers");

const provider = new ethers.providers.JsonRpcProvider("YOUR_RPC_URL");
const signer = new ethers.Wallet("YOUR_PRIVATE_KEY", provider);

const contractAddress = "CONTRACT_ADDRESS";
const abi = [...]; // 合约 ABI

const token = new ethers.Contract(contractAddress, abi, signer);
```

#### 查询基本信息
```javascript
async function getTokenInfo() {
    const name = await token.name();
    const symbol = await token.symbol();
    const totalSupply = await token.totalSupply();
    const balance = await token.balanceOf(signer.address);
    
    console.log(`代币: ${name} (${symbol})`);
    console.log(`总供应量: ${ethers.utils.formatEther(totalSupply)}`);
    console.log(`我的余额: ${ethers.utils.formatEther(balance)}`);
}
```

#### 转账
```javascript
async function transfer(to, amount) {
    const tx = await token.transfer(to, ethers.utils.parseEther(amount));
    const receipt = await tx.wait();
    console.log(`转账成功: ${receipt.transactionHash}`);
}
```

#### 查询税收信息
```javascript
async function getTaxInfo() {
    const buyTax = await token.buyTax();
    const sellTax = await token.sellTax();
    const maxTx = await token.maxTxAmount();
    const maxWallet = await token.maxWalletSize();
    
    console.log(`买入税: ${buyTax}%`);
    console.log(`卖出税: ${sellTax}%`);
    console.log(`最大交易: ${ethers.utils.formatEther(maxTx)}`);
    console.log(`最大钱包: ${ethers.utils.formatEther(maxWallet)}`);
}
```

#### 管理员操作 (仅所有者)
```javascript
async function updateTax(newBuyTax, newSellTax) {
    const tx1 = await token.updateBuyTax(newBuyTax);
    await tx1.wait();
    
    const tx2 = await token.updateSellTax(newSellTax);
    await tx2.wait();
    
    console.log("税收更新成功");
}

async function blacklistAddress(address, blacklisted) {
    const tx = await token.blacklistAddress(address, blacklisted);
    await tx.wait();
    console.log(`地址 ${address} ${blacklisted ? '已加入' : '已移除'}黑名单`);
}
```

### Solidity 集成

#### 在其他合约中使用
```solidity
import "./interfaces/IERC20Extended.sol";

contract MyContract {
    IERC20Extended public shibToken;
    
    constructor(address _shibToken) {
        shibToken = IERC20Extended(_shibToken);
    }
    
    function checkTaxInfo() external view returns (uint256 buyTax, uint256 sellTax) {
        buyTax = shibToken.buyTax();
        sellTax = shibToken.sellTax();
    }
    
    function safeTransfer(address to, uint256 amount) external {
        require(!shibToken.isBlacklisted(to), "Recipient is blacklisted");
        require(amount <= shibToken.maxTxAmount(), "Amount exceeds max transaction");
        
        shibToken.transferFrom(msg.sender, to, amount);
    }
}
```

## 错误处理

### 常见错误
- `"Tax cannot exceed 25%"`: 税收超过最大限制
- `"Transfer amount exceeds the maxTxAmount"`: 转账金额超过限制
- `"Recipient wallet would exceed max wallet size"`: 接收钱包超过最大持有量
- `"Blacklisted address cannot transfer"`: 黑名单地址无法转账
- `"Trading not enabled"`: 交易未启用
- `"Contract is paused"`: 合约已暂停

### 错误处理示例
```javascript
try {
    const tx = await token.transfer(to, amount);
    await tx.wait();
} catch (error) {
    if (error.message.includes("exceeds the maxTxAmount")) {
        console.error("转账金额超过限制");
    } else if (error.message.includes("Blacklisted")) {
        console.error("地址在黑名单中");
    } else {
        console.error("转账失败:", error.message);
    }
}
```

## 最佳实践

### 1. 安全考虑
- 始终检查返回值
- 处理所有可能的异常
- 验证输入参数
- 使用最新的库版本

### 2. Gas 优化
- 批量操作减少交易次数
- 合理设置 Gas Limit
- 监控 Gas 价格

### 3. 用户体验
- 提供清晰的错误信息
- 显示税收和限制信息
- 实时更新余额和状态

### 4. 监控和日志
- 监听重要事件
- 记录关键操作
- 设置异常告警

## 版本历史

- **v1.0.0**: 初始版本，包含基本功能
- **v1.1.0**: 添加批量操作功能
- **v1.2.0**: 优化 Gas 使用和安全性

## 支持和联系

- **文档**: [GitHub Repository](https://github.com/your-repo)
- **问题反馈**: [GitHub Issues](https://github.com/your-repo/issues)
- **社区**: [Discord/Telegram](https://your-community-link)
- **邮箱**: support@your-project.com