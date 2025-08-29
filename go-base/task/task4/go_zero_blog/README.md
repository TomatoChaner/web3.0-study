# Go-Zero Blog API

基于 go-zero 框架开发的博客系统 API，提供用户认证、文章管理和评论功能。

## 功能特性

- 🔐 用户认证（注册、登录、JWT）
- 📝 文章管理（CRUD操作）
- 💬 评论系统
- 🛡️ 统一错误处理
- 📊 结构化日志记录
- 🗄️ MySQL 数据库支持
- 🔒 JWT 令牌认证
- 📄 分页查询支持

## 技术栈

- **框架**: go-zero
- **数据库**: MySQL
- **ORM**: GORM
- **认证**: JWT
- **密码加密**: bcrypt
- **日志**: go-zero logx

## 项目结构

```
go_zero_blog/
├── blog.api              # API 定义文件
├── blog.go               # 主程序入口
├── etc/
│   └── blog.yaml         # 配置文件
├── internal/
│   ├── config/           # 配置结构
│   ├── handler/          # HTTP 处理器
│   ├── logic/            # 业务逻辑
│   ├── middleware/       # 中间件
│   ├── model/            # 数据模型
│   ├── svc/              # 服务上下文
│   ├── types/            # 类型定义
│   └── utils/            # 工具函数
├── go.mod
├── go.sum
└── README.md
```

## 快速开始

### 1. 环境要求

- Go 1.19+
- MySQL 5.7+
- go-zero 框架

### 2. 安装依赖

```bash
go mod tidy
```

### 3. 数据库配置

创建 MySQL 数据库：

```sql
CREATE DATABASE blog_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 4. 配置文件

编辑 `etc/blog.yaml` 配置文件：

```yaml
Name: blog-api
Host: 0.0.0.0
Port: 8888

# 数据库配置
Database:
  Host: localhost
  Port: 3306
  Username: root
  Password: your_password
  DBName: blog_db
  Charset: utf8mb4
  ParseTime: true
  Loc: Local

# JWT 配置
JWT:
  Secret: your_jwt_secret_key
  Expire: 86400  # 24小时

# 日志配置
Log:
  Level: info
  Mode: console  # console 或 file
  Path: ./logs   # 文件模式下的日志路径
```

### 5. 运行服务

```bash
go run blog.go
```

服务将在 `http://localhost:8888` 启动。

## API 文档

### 用户认证

#### 用户注册

```http
POST /api/register
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123"
}
```

#### 用户登录

```http
POST /api/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "password123"
}
```

#### 获取用户信息

```http
GET /api/user/info
Authorization: Bearer <jwt_token>
```

### 文章管理

#### 创建文章

```http
POST /api/posts
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "title": "文章标题",
  "content": "文章内容"
}
```

#### 获取文章列表

```http
GET /api/posts?page=1&pageSize=10
```

#### 获取文章详情

```http
GET /api/posts/{id}
```

#### 更新文章

```http
PUT /api/posts/{id}
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "title": "更新的标题",
  "content": "更新的内容"
}
```

#### 删除文章

```http
DELETE /api/posts/{id}
Authorization: Bearer <jwt_token>
```

### 评论管理

#### 创建评论

```http
POST /api/comments
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "postId": 1,
  "content": "评论内容"
}
```

#### 获取评论列表

```http
GET /api/comments?postId=1&page=1&pageSize=10
```

## 响应格式

### 成功响应

```json
{
  "code": 200,
  "message": "success",
  "data": {
    // 响应数据
  }
}
```

### 错误响应

```json
{
  "code": 400,
  "message": "错误信息",
  "data": null
}
```

## 数据模型

### 用户模型

```go
type User struct {
    ID        uint      `gorm:"primarykey" json:"id"`
    Username  string    `gorm:"uniqueIndex;size:50;not null" json:"username"`
    Email     string    `gorm:"uniqueIndex;size:100;not null" json:"email"`
    Password  string    `gorm:"size:255;not null" json:"-"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

### 文章模型

```go
type Post struct {
    ID        uint      `gorm:"primarykey" json:"id"`
    Title     string    `gorm:"size:200;not null" json:"title"`
    Content   string    `gorm:"type:text;not null" json:"content"`
    UserID    uint      `gorm:"not null;index" json:"user_id"`
    User      User      `gorm:"foreignKey:UserID" json:"user"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

### 评论模型

```go
type Comment struct {
    ID        uint      `gorm:"primarykey" json:"id"`
    Content   string    `gorm:"type:text;not null" json:"content"`
    PostID    uint      `gorm:"not null;index" json:"post_id"`
    Post      Post      `gorm:"foreignKey:PostID" json:"post"`
    UserID    uint      `gorm:"not null;index" json:"user_id"`
    User      User      `gorm:"foreignKey:UserID" json:"user"`
    CreatedAt time.Time `json:"created_at"`
}
```

## 开发指南

### 添加新的 API

1. 在 `blog.api` 文件中定义新的 API 接口
2. 运行 `goctl api go -api blog.api -dir .` 重新生成代码
3. 在对应的 logic 文件中实现业务逻辑

### 中间件使用

项目包含以下中间件：

- **认证中间件**: 验证 JWT 令牌
- **错误处理中间件**: 统一处理 panic 和错误
- **日志中间件**: 记录请求日志

### 日志配置

支持控制台和文件两种日志模式：

- **控制台模式**: 适用于开发环境
- **文件模式**: 适用于生产环境，支持日志轮转

## 部署

### Docker 部署

```dockerfile
FROM golang:1.19-alpine AS builder

WORKDIR /app
COPY . .
RUN go mod tidy && go build -o blog blog.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/blog .
COPY --from=builder /app/etc ./etc
CMD ["./blog"]
```

### 生产环境配置

1. 修改数据库连接配置
2. 设置强密码的 JWT 密钥
3. 配置文件日志模式
4. 设置适当的日志级别

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！