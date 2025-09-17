# MetaNode Staking API 文档

## 概述

MetaNode Staking API 提供了与质押合约交互的RESTful接口，支持用户管理、质押操作、奖励查询等功能。

## 基础信息

- **Base URL**: `http://localhost:3001/api`
- **认证方式**: 基于钱包地址的签名验证
- **数据格式**: JSON
- **速率限制**: 每15分钟100次请求

## 通用响应格式

### 成功响应
```json
{
  "success": true,
  "data": {
    // 响应数据
  },
  "message": "操作成功"
}
```

### 错误响应
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述"
  }
}
```

## API 端点

### 1. 用户管理

#### 1.1 获取用户信息
```
GET /users/:address
```

**参数:**
- `address` (string): 用户钱包地址

**响应:**
```json
{
  "success": true,
  "data": {
    "address": "0x...",
    "totalStaked": "1000000000000000000",
    "totalRewards": "50000000000000000",
    "stakingCount": 3,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 1.2 创建或更新用户
```
POST /users
```

**请求体:**
```json
{
  "address": "0x...",
  "signature": "0x...",
  "message": "Welcome to MetaNode Staking"
}
```

### 2. 质押管理

#### 2.1 获取用户质押记录
```
GET /stakes/:address
```

**查询参数:**
- `page` (number, optional): 页码，默认1
- `limit` (number, optional): 每页数量，默认10
- `status` (string, optional): 状态筛选 (active, unstaked, emergency)

**响应:**
```json
{
  "success": true,
  "data": {
    "stakes": [
      {
        "id": "uuid",
        "userAddress": "0x...",
        "amount": "1000000000000000000",
        "stakingType": "flexible",
        "apy": 1200,
        "startTime": "2024-01-01T00:00:00Z",
        "endTime": null,
        "status": "active",
        "transactionHash": "0x...",
        "blockNumber": 12345678
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 25,
      "totalPages": 3
    }
  }
}
```

#### 2.2 获取单个质押详情
```
GET /stakes/detail/:stakeId
```

#### 2.3 创建质押记录
```
POST /stakes
```

**请求体:**
```json
{
  "userAddress": "0x...",
  "amount": "1000000000000000000",
  "stakingType": "flexible",
  "transactionHash": "0x...",
  "blockNumber": 12345678
}
```

### 3. 奖励管理

#### 3.1 获取用户奖励记录
```
GET /rewards/:address
```

**查询参数:**
- `page` (number, optional): 页码
- `limit` (number, optional): 每页数量
- `startDate` (string, optional): 开始日期 (YYYY-MM-DD)
- `endDate` (string, optional): 结束日期 (YYYY-MM-DD)

**响应:**
```json
{
  "success": true,
  "data": {
    "rewards": [
      {
        "id": "uuid",
        "userAddress": "0x...",
        "stakeId": "uuid",
        "amount": "50000000000000000",
        "rewardType": "staking",
        "claimedAt": "2024-01-01T00:00:00Z",
        "transactionHash": "0x...",
        "blockNumber": 12345678
      }
    ],
    "summary": {
      "totalRewards": "500000000000000000",
      "claimedRewards": "300000000000000000",
      "pendingRewards": "200000000000000000"
    }
  }
}
```

#### 3.2 计算待领取奖励
```
GET /rewards/:address/pending
```

#### 3.3 记录奖励领取
```
POST /rewards/claim
```

### 4. 统计数据

#### 4.1 获取平台统计
```
GET /stats/platform
```

**响应:**
```json
{
  "success": true,
  "data": {
    "totalStaked": "10000000000000000000000",
    "totalUsers": 1250,
    "totalRewardsDistributed": "500000000000000000000",
    "averageAPY": 1150,
    "activeStakes": 3420
  }
}
```

#### 4.2 获取用户统计
```
GET /stats/user/:address
```

#### 4.3 获取历史数据
```
GET /stats/history
```

**查询参数:**
- `period` (string): 时间周期 (daily, weekly, monthly)
- `days` (number): 天数，默认30

### 5. 通知管理

#### 5.1 获取用户通知
```
GET /notifications/:address
```

#### 5.2 标记通知为已读
```
PUT /notifications/:id/read
```

#### 5.3 创建通知
```
POST /notifications
```

### 6. 管理员接口

#### 6.1 获取系统健康状态
```
GET /admin/health
```

#### 6.2 获取系统指标
```
GET /admin/metrics
```

#### 6.3 管理合约状态
```
POST /admin/contract/pause
POST /admin/contract/unpause
```

## WebSocket 实时更新

### 连接
```javascript
const ws = new WebSocket('ws://localhost:3001/ws');
```

### 订阅事件
```javascript
// 订阅用户相关事件
ws.send(JSON.stringify({
  type: 'subscribe',
  channel: 'user',
  address: '0x...'
}));

// 订阅平台统计
ws.send(JSON.stringify({
  type: 'subscribe',
  channel: 'platform'
}));
```

### 事件类型
- `stake_created`: 新质押创建
- `stake_unstaked`: 质押赎回
- `rewards_claimed`: 奖励领取
- `platform_stats_updated`: 平台统计更新

## 错误代码

| 代码 | 描述 |
|------|------|
| `INVALID_ADDRESS` | 无效的钱包地址 |
| `INSUFFICIENT_BALANCE` | 余额不足 |
| `STAKE_NOT_FOUND` | 质押记录不存在 |
| `UNAUTHORIZED` | 未授权访问 |
| `RATE_LIMIT_EXCEEDED` | 请求频率超限 |
| `INTERNAL_ERROR` | 服务器内部错误 |

## 使用示例

### JavaScript/Node.js
```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'http://localhost:3001/api',
  timeout: 10000
});

// 获取用户信息
async function getUserInfo(address) {
  try {
    const response = await api.get(`/users/${address}`);
    return response.data;
  } catch (error) {
    console.error('Error:', error.response.data);
  }
}

// 获取质押记录
async function getStakes(address, page = 1) {
  const response = await api.get(`/stakes/${address}?page=${page}`);
  return response.data;
}
```

### Python
```python
import requests

class MetaNodeAPI:
    def __init__(self, base_url="http://localhost:3001/api"):
        self.base_url = base_url
    
    def get_user_info(self, address):
        response = requests.get(f"{self.base_url}/users/{address}")
        return response.json()
    
    def get_stakes(self, address, page=1):
        response = requests.get(f"{self.base_url}/stakes/{address}?page={page}")
        return response.json()
```

## 部署和配置

### 环境变量
参考 `.env.example` 文件配置必要的环境变量。

### 启动服务
```bash
# 开发环境
npm run start:api

# 生产环境
NODE_ENV=production npm run start:api
```

### 健康检查
```bash
curl http://localhost:3001/api/admin/health
```