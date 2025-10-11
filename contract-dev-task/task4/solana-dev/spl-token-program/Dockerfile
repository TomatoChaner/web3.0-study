# 使用官方Node.js镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    curl \
    bash \
    git \
    python3 \
    make \
    g++

# 安装Rust和Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# 安装Solana CLI
RUN sh -c "$(curl -sSfL https://release.solana.com/v1.18.0/install)"
ENV PATH="/root/.local/share/solana/install/active_release/bin:${PATH}"

# 安装Anchor
RUN cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
RUN avm install latest
RUN avm use latest

# 复制package.json和yarn.lock
COPY package.json yarn.lock* ./

# 安装Node.js依赖
RUN yarn install --frozen-lockfile

# 复制项目文件
COPY . .

# 构建程序
RUN anchor build

# 暴露端口
EXPOSE 3000 8899

# 创建启动脚本
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# 启动Solana测试验证器\n\
solana-test-validator --reset &\n\
VALIDATOR_PID=$!\n\
\n\
# 等待验证器启动\n\
sleep 10\n\
\n\
# 部署程序\n\
anchor deploy\n\
\n\
# 启动前端服务器\n\
node scripts/dev-server.js &\n\
SERVER_PID=$!\n\
\n\
# 优雅关闭处理\n\
trap "kill $VALIDATOR_PID $SERVER_PID" EXIT\n\
\n\
# 保持容器运行\n\
wait\n\
' > /app/start.sh && chmod +x /app/start.sh

# 启动命令
CMD ["/app/start.sh"]