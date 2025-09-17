#!/bin/bash

# 自动化 Vercel 部署脚本
# 使用方法: ./scripts/deploy.sh

echo "🚀 开始自动化部署到 Vercel..."

# 检查是否安装了 Vercel CLI
if ! command -v vercel &> /dev/null; then
    echo "📦 安装 Vercel CLI..."
    npm install -g vercel
fi

# 检查是否已登录
echo "🔐 检查 Vercel 登录状态..."
if ! vercel whoami &> /dev/null; then
    echo "请先登录 Vercel:"
    vercel login
fi

# 确保环境变量文件存在
if [ ! -f ".env.local" ]; then
    echo "❌ 错误: .env.local 文件不存在"
    echo "请先创建 .env.local 文件并配置环境变量"
    exit 1
fi

# 提交环境变量文件到 Git
echo "📝 提交环境变量文件..."
git add .env.local
git add vercel.json
git commit -m "Update deployment configuration" || echo "没有新的更改需要提交"

# 推送到远程仓库
echo "⬆️ 推送到远程仓库..."
git push

# 部署到 Vercel
echo "🌐 部署到 Vercel..."
vercel --prod

echo "✅ 部署完成！"
echo "🔗 你的网站将在几分钟内可用"

# 获取部署信息
echo "📊 获取部署信息..."
vercel ls