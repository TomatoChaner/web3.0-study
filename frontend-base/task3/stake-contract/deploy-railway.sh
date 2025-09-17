#!/bin/bash

# 🚀 Railway 部署脚本
# 使用方法: ./deploy-railway.sh [init|deploy|logs|status]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取操作类型
ACTION=${1:-deploy}

echo -e "${BLUE}🚀 Railway 部署工具${NC}"
echo "=================================="

# 检查是否安装了 Railway CLI
check_railway_cli() {
    if ! command -v railway &> /dev/null; then
        echo -e "${RED}❌ Railway CLI 未安装${NC}"
        echo "请运行以下命令安装:"
        echo "npm install -g @railway/cli"
        echo "或访问: https://docs.railway.app/develop/cli"
        exit 1
    fi
    echo -e "${GREEN}✅ Railway CLI 已安装${NC}"
}

# 检查是否已登录
check_railway_auth() {
    if ! railway whoami &> /dev/null; then
        echo -e "${YELLOW}⚠️  请先登录 Railway${NC}"
        railway login
    fi
    echo -e "${GREEN}✅ Railway 认证成功${NC}"
}

# 初始化 Railway 项目
init_project() {
    echo -e "${BLUE}🔧 初始化 Railway 项目...${NC}"
    
    # 检查是否已经初始化
    if [ -f "railway.toml" ]; then
        echo -e "${YELLOW}⚠️  项目已初始化，跳过...${NC}"
        return
    fi
    
    # 初始化项目
    railway init
    
    # 添加 PostgreSQL 服务
    echo -e "${BLUE}📦 添加 PostgreSQL 数据库...${NC}"
    railway add postgresql
    
    echo -e "${GREEN}✅ 项目初始化完成${NC}"
}

# 设置环境变量
setup_env_vars() {
    echo -e "${BLUE}🔧 设置环境变量...${NC}"
    
    # 检查 .env 文件是否存在
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}⚠️  .env 文件不存在，请先创建并配置环境变量${NC}"
        echo "可以从 .env.example 复制: cp .env.example .env"
        return
    fi
    
    # 读取 .env 文件并设置环境变量
    echo "正在设置环境变量..."
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        if [[ $key =~ ^[[:space:]]*# ]] || [[ -z $key ]]; then
            continue
        fi
        
        # 移除前后空格
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        if [[ -n $key && -n $value ]]; then
            railway variables set "$key=$value" 2>/dev/null || true
        fi
    done < .env
    
    echo -e "${GREEN}✅ 环境变量设置完成${NC}"
}

# 部署应用
deploy_app() {
    echo -e "${BLUE}🚀 部署应用到 Railway...${NC}"
    
    # 运行测试
    echo "🧪 运行测试..."
    npm test || {
        echo -e "${RED}❌ 测试失败，请修复后重试${NC}"
        exit 1
    }
    
    # 编译合约
    echo "🔨 编译智能合约..."
    npm run compile || {
        echo -e "${RED}❌ 合约编译失败${NC}"
        exit 1
    }
    
    # 部署到 Railway
    echo "🚀 部署中..."
    railway up
    
    echo -e "${GREEN}🎉 部署完成！${NC}"
}

# 查看日志
view_logs() {
    echo -e "${BLUE}📋 查看应用日志...${NC}"
    railway logs
}

# 查看状态
check_status() {
    echo -e "${BLUE}📊 检查应用状态...${NC}"
    railway status
    echo ""
    echo -e "${BLUE}🌐 获取应用 URL...${NC}"
    railway domain
}

# 主函数
main() {
    check_railway_cli
    check_railway_auth
    
    case $ACTION in
        "init")
            init_project
            setup_env_vars
            ;;
        "deploy")
            deploy_app
            ;;
        "logs")
            view_logs
            ;;
        "status")
            check_status
            ;;
        *)
            echo -e "${RED}❌ 未知操作: $ACTION${NC}"
            echo "可用操作: init, deploy, logs, status"
            exit 1
            ;;
    esac
}

# 显示帮助信息
show_help() {
    echo "🚀 Railway 部署脚本使用说明"
    echo ""
    echo "用法: ./deploy-railway.sh [操作]"
    echo ""
    echo "可用操作:"
    echo "  init     - 初始化 Railway 项目并设置数据库"
    echo "  deploy   - 部署应用到 Railway"
    echo "  logs     - 查看应用日志"
    echo "  status   - 查看应用状态和 URL"
    echo ""
    echo "示例:"
    echo "  ./deploy-railway.sh init     # 首次使用"
    echo "  ./deploy-railway.sh deploy   # 部署应用"
    echo "  ./deploy-railway.sh logs     # 查看日志"
    echo ""
}

# 检查是否需要显示帮助
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# 运行主函数
main

echo ""
echo -e "${GREEN}✨ 操作完成！${NC}"
echo ""
echo "🔗 有用的命令:"
echo "  railway logs           # 查看实时日志"
echo "  railway variables      # 管理环境变量"
echo "  railway domain         # 管理域名"
echo "  railway status         # 查看服务状态"