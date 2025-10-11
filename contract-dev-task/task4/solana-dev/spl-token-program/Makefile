# SPL Token Program Makefile

.PHONY: help install build deploy test clean dev stop lint format

# 默认目标
help:
	@echo "SPL Token Program - 可用命令:"
	@echo ""
	@echo "  setup     - 安装所有依赖和工具"
	@echo "  install   - 安装Node.js依赖"
	@echo "  build     - 构建Anchor程序"
	@echo "  deploy    - 部署程序到当前网络"
	@echo "  test      - 运行测试"
	@echo "  dev       - 启动开发环境"
	@echo "  clean     - 清理构建文件"
	@echo "  lint      - 检查代码格式"
	@echo "  format    - 格式化代码"
	@echo "  validator - 启动本地验证器"
	@echo "  stop      - 停止本地验证器"
	@echo ""
	@echo "  Docker命令:"
	@echo "  docker-build  - 构建Docker镜像"
	@echo "  docker-run    - 运行Docker容器"
	@echo "  docker-up     - 启动Docker Compose"
	@echo "  docker-down   - 停止Docker Compose"
	@echo ""
	@echo "  代币管理:"
	@echo "  token-create  - 创建新代币"
	@echo "  token-info    - 查看代币信息"

# 环境设置
setup:
	@echo "🔧 设置开发环境..."
	@echo "检查Rust安装..."
	@which rustc || (echo "请先安装Rust: https://rustup.rs/" && exit 1)
	@echo "检查Solana CLI安装..."
	@which solana || (echo "请先安装Solana CLI" && exit 1)
	@echo "检查Anchor安装..."
	@which anchor || (echo "请先安装Anchor" && exit 1)
	@echo "安装Node.js依赖..."
	@yarn install
	@echo "配置Solana为本地网络..."
	@solana config set --url localhost
	@echo "✅ 环境设置完成!"

# 安装依赖
install:
	@echo "📦 安装依赖..."
	@yarn install

# 构建程序
build:
	@echo "🔨 构建程序..."
	@anchor build

# 部署程序
deploy: build
	@echo "🚀 部署程序..."
	@anchor deploy

# 运行测试
test:
	@echo "🧪 运行测试..."
	@anchor test

# 清理构建文件
clean:
	@echo "🧹 清理构建文件..."
	@anchor clean
	@rm -rf node_modules/.cache
	@rm -rf target/

# 启动开发环境
dev:
	@echo "🚀 启动开发环境..."
	@echo "请确保在另一个终端运行: make validator"
	@yarn dev

# 启动本地验证器
validator:
	@echo "🔗 启动Solana测试验证器..."
	@solana-test-validator --reset

# 停止本地验证器
stop:
	@echo "🛑 停止验证器..."
	@pkill -f solana-test-validator || true

# 代码检查
lint:
	@echo "🔍 检查代码格式..."
	@yarn lint

# 格式化代码
format:
	@echo "✨ 格式化代码..."
	@yarn lint:fix

# Docker命令
docker-build:
	@echo "🐳 构建Docker镜像..."
	@docker build -t spl-token-program .

docker-run: docker-build
	@echo "🐳 运行Docker容器..."
	@docker run -p 3000:3000 -p 8899:8899 spl-token-program

docker-up:
	@echo "🐳 启动Docker Compose..."
	@docker-compose up -d

docker-down:
	@echo "🐳 停止Docker Compose..."
	@docker-compose down

# 代币管理命令
token-create:
	@echo "🪙 创建新代币..."
	@yarn token:create

token-info:
	@echo "📊 查看代币信息..."
	@yarn token:info

# 快速启动完整开发环境
quick-start: stop
	@echo "⚡ 快速启动完整开发环境..."
	@echo "1. 启动验证器..."
	@solana-test-validator --reset &
	@sleep 5
	@echo "2. 构建和部署程序..."
	@make deploy
	@echo "3. 启动前端服务器..."
	@yarn dev

# 重置环境
reset: stop clean
	@echo "🔄 重置开发环境..."
	@rm -f keypair.json mint-address.txt
	@make setup

# 检查环境
check:
	@echo "🔍 检查开发环境..."
	@echo "Rust版本:"
	@rustc --version
	@echo "Solana版本:"
	@solana --version
	@echo "Anchor版本:"
	@anchor --version
	@echo "Node.js版本:"
	@node --version
	@echo "Yarn版本:"
	@yarn --version
	@echo "当前Solana配置:"
	@solana config get

# 生产部署到devnet
deploy-devnet:
	@echo "🌐 部署到Devnet..."
	@solana config set --url devnet
	@solana airdrop 2
	@anchor deploy --provider.cluster devnet
	@echo "✅ 部署到Devnet完成!"

# 生产部署到mainnet
deploy-mainnet:
	@echo "⚠️  部署到Mainnet..."
	@read -p "确认要部署到Mainnet吗? (y/N): " confirm && [ "$$confirm" = "y" ]
	@solana config set --url mainnet-beta
	@anchor deploy --provider.cluster mainnet-beta
	@echo "✅ 部署到Mainnet完成!"