# 🚀 Vercel 部署指南

## 📋 部署前准备

### 1. 确保项目准备就绪
- ✅ 本地构建成功 (`npm run build`)
- ✅ 所有 TypeScript 错误已修复
- ✅ 环境变量配置完成

### 2. 必需的外部服务
- **Infura 账户**: 获取 RPC URL
- **WalletConnect 项目**: 获取 Project ID
- **智能合约**: 已部署的合约地址

## 🔧 部署步骤

### 方法一：通过 Vercel CLI (推荐)

1. **安装 Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **登录 Vercel**
   ```bash
   vercel login
   ```

3. **部署项目**
   ```bash
   cd stake-frontend
   vercel
   ```

4. **配置环境变量**
   ```bash
   vercel env add NEXT_PUBLIC_RPC_URL
   vercel env add NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID
   vercel env add NEXT_PUBLIC_STAKE_CONTRACT_ADDRESS
   # ... 添加其他环境变量
   ```

### 方法二：通过 Vercel 网站

1. **连接 GitHub**
   - 访问 [vercel.com](https://vercel.com)
   - 使用 GitHub 账户登录
   - 导入你的项目仓库

2. **配置项目设置**
   - Framework Preset: `Next.js`
   - Root Directory: `stake-frontend`
   - Build Command: `npm run build`
   - Output Directory: `.next`

3. **设置环境变量**
   在 Vercel 项目设置中添加以下环境变量：

## 🔑 环境变量配置

### 必需的环境变量

| 变量名 | 描述 | 示例值 |
|--------|------|--------|
| `NEXT_PUBLIC_CHAIN_ID` | 区块链网络ID | `11155111` (Sepolia) |
| `NEXT_PUBLIC_RPC_URL` | RPC 节点地址 | `https://sepolia.infura.io/v3/YOUR_KEY` |
| `NEXT_PUBLIC_STAKE_CONTRACT_ADDRESS` | 质押合约地址 | `0x...` |
| `NEXT_PUBLIC_METANODE_TOKEN_ADDRESS` | 代币合约地址 | `0x...` |
| `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID` | WalletConnect 项目ID | `your_project_id` |

### 可选的环境变量

| 变量名 | 描述 | 示例值 |
|--------|------|--------|
| `NEXT_PUBLIC_APP_NAME` | 应用名称 | `"Stake Frontend"` |
| `NEXT_PUBLIC_APP_DESCRIPTION` | 应用描述 | `"去中心化质押应用"` |
| `NEXT_PUBLIC_API_URL` | 后端API地址 | `https://api.yourdomain.com` |

## 📝 部署后检查清单

### ✅ 功能测试
- [ ] 网站可以正常访问
- [ ] 钱包连接功能正常
- [ ] 智能合约交互正常
- [ ] 页面样式显示正确
- [ ] 响应式设计在移动端正常

### ✅ 性能检查
- [ ] 页面加载速度 < 3秒
- [ ] Lighthouse 分数 > 90
- [ ] 无 JavaScript 错误
- [ ] 无控制台警告

### ✅ SEO 优化
- [ ] 页面标题和描述正确
- [ ] Open Graph 标签设置
- [ ] 网站图标显示正常

## 🔄 更新部署

### 自动部署
- 推送到 `main` 分支会自动触发部署
- 推送到其他分支会创建预览部署

### 手动部署
```bash
vercel --prod  # 部署到生产环境
```

## 🐛 常见问题

### 1. 构建失败
**问题**: TypeScript 编译错误
**解决**: 运行 `npm run type-check` 检查类型错误

### 2. 环境变量未生效
**问题**: 前端无法读取环境变量
**解决**: 确保变量名以 `NEXT_PUBLIC_` 开头

### 3. 钱包连接失败
**问题**: WalletConnect 无法连接
**解决**: 检查 `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID` 是否正确

### 4. 合约交互失败
**问题**: 无法调用智能合约
**解决**: 
- 检查合约地址是否正确
- 确认网络ID匹配
- 验证 RPC URL 可用

## 📊 监控和分析

### Vercel Analytics
```bash
npm install @vercel/analytics
```

在 `app/layout.tsx` 中添加：
```tsx
import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
```

## 🔒 安全配置

### 1. 域名配置
- 在 Vercel 项目设置中配置自定义域名
- 启用 HTTPS (自动配置)

### 2. 安全头部
已在 `vercel.json` 中配置：
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`

## 📞 支持

如果遇到部署问题：
1. 查看 Vercel 部署日志
2. 检查浏览器控制台错误
3. 参考 [Vercel 官方文档](https://vercel.com/docs)

---

🎉 **部署完成后，你的 DApp 就可以在全球范围内访问了！**