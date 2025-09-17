#!/bin/bash

# 🚀 Vercel 部署脚本
# 使用方法: ./deploy.sh [production|preview]

set -e

echo "🔧 开始部署到 Vercel..."

# 检查参数
ENVIRONMENT=${1:-preview}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否安装了 Vercel CLI
if ! command -v vercel &> /dev/null; then
    echo -e "${RED}❌ Vercel CLI 未安装${NC}"
    echo "请运行: npm install -g vercel"
    exit 1
fi

# 检查是否已登录
if ! vercel whoami &> /dev/null; then
    echo -e "${YELLOW}⚠️  请先登录 Vercel${NC}"
    vercel login
fi

echo -e "${GREEN}✅ 环境检查通过${NC}"

# 运行构建测试
echo "🔨 测试本地构建..."
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 本地构建成功${NC}"
else
    echo -e "${RED}❌ 本地构建失败，请检查错误${NC}"
    exit 1
fi

# 部署到 Vercel
echo "🚀 部署到 Vercel ($ENVIRONMENT)..."

if [ "$ENVIRONMENT" = "production" ]; then
    vercel --prod
    echo -e "${GREEN}🎉 生产环境部署完成！${NC}"
else
    vercel
    echo -e "${GREEN}🎉 预览环境部署完成！${NC}"
fi

echo ""
echo "📋 部署后检查清单:"
echo "  □ 检查网站是否可以访问"
echo "  □ 测试钱包连接功能"
echo "  □ 验证智能合约交互"
echo "  □ 检查移动端显示"
echo ""
echo "🔗 有用的命令:"
echo "  vercel --help          # 查看帮助"
echo "  vercel logs            # 查看部署日志"
echo "  vercel env ls          # 查看环境变量"
echo "  vercel domains         # 管理域名"
echo ""
echo -e "${GREEN}✨ 部署完成！${NC}"