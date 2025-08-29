# Gin Blog API

个人博客系统后端API，使用Go语言、Gin框架和GORM库开发，支持用户认证、文章管理和评论功能。

## 功能特性

- 用户注册和登录
- JWT身份认证
- 文章CRUD操作
- 评论功能
- 分页查询
- 统一错误处理
- 日志记录

## 技术栈

- **后端框架**: Gin
- **ORM**: GORM
- **数据库**: MySQL
- **身份认证**: JWT
- **日志**: Logrus
- **密码加密**: bcrypt

## 环境要求

- Go 1.19+
- MySQL 5.7+

## 安装和运行

### 1. 克隆项目

```bash
git clone <repository-url>
cd gin_blog
```

### 2. 安装依赖

```bash
go mod tidy
```

### 3. 配置数据库

确保MySQL服务正在运行，并创建数据库：

```sql
CREATE DATABASE gin_blog CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 4. 修改数据库配置

在 `config/database.go` 文件中修改数据库连接信息：

```go
func GetDefaultConfig() *DatabaseConfig {
    return &DatabaseConfig{
        Host:     "localhost",
        Port:     "3306",
        User:     "root",
        Password: "lh123456",  // 修改为你的密码
        DBName:   "gin_blog",
        Charset:  "utf8mb4",
    }
}
```

### 5. 运行项目

```bash
go run main.go
```

服务器将在 `http://localhost:8080` 启动。

## API 接口文档

### 基础信息

- **Base URL**: `http://localhost:8080/api/v1`
- **认证方式**: Bearer Token (JWT)
- **Content-Type**: `application/json`

### 健康检查

```
GET /health
```

### 用户认证

#### 用户注册

```
POST /api/v1/auth/register
```

**请求体**:
```json
{
    "username": "testuser",
    "password": "password123",
    "email": "test@example.com"
}
```

#### 用户登录

```
POST /api/v1/auth/login
```

**请求体**:
```json
{
    "username": "testuser",
    "password": "password123"
}
```

**响应**:
```json
{
    "code": 200,
    "message": "登录成功",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "user_id": 1,
        "username": "testuser",
        "email": "test@example.com"
    }
}
```

#### 获取用户信息

```
GET /api/v1/user/profile
Authorization: Bearer <token>
```

### 文章管理

#### 获取文章列表

```
GET /api/v1/posts?page=1&page_size=10
```

#### 获取单个文章

```
GET /api/v1/posts/{id}
```

#### 创建文章

```
POST /api/v1/posts
Authorization: Bearer <token>
```

**请求体**:
```json
{
    "title": "文章标题",
    "content": "文章内容"
}
```

#### 更新文章

```
PUT /api/v1/posts/{id}
Authorization: Bearer <token>
```

**请求体**:
```json
{
    "title": "新标题",
    "content": "新内容"
}
```

#### 删除文章

```
DELETE /api/v1/posts/{id}
Authorization: Bearer <token>
```

### 评论管理

#### 获取文章评论

```
GET /api/v1/comments/post/{post_id}?page=1&page_size=10
```

#### 创建评论

```
POST /api/v1/comments
Authorization: Bearer <token>
```

**请求体**:
```json
{
    "content": "评论内容",
    "post_id": 1
}
```

#### 删除评论

```
DELETE /api/v1/comments/{id}
Authorization: Bearer <token>
```

## 响应格式

### 成功响应

```json
{
    "code": 200,
    "message": "success",
    "data": {}
}
```

### 错误响应

```json
{
    "code": 400,
    "message": "错误信息"
}
```

### 分页响应

```json
{
    "code": 200,
    "message": "success",
    "data": {
        "total": 100,
        "page": 1,
        "page_size": 10,
        "data": []
    }
}
```

## 状态码说明

- `200` - 成功
- `400` - 请求参数错误
- `401` - 未授权
- `403` - 禁止访问
- `404` - 资源不存在
- `500` - 服务器内部错误

## 测试

### 使用 curl 测试

1. **注册用户**:
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123","email":"test@example.com"}'
```

2. **用户登录**:
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

3. **创建文章**:
```bash
curl -X POST http://localhost:8080/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-token>" \
  -d '{"title":"测试文章","content":"这是一篇测试文章"}'
```

### 使用 Postman 测试

1. 导入API接口到Postman
2. 设置环境变量 `base_url` 为 `http://localhost:8080`
3. 在需要认证的请求中添加 `Authorization: Bearer <token>` 头部

## 项目结构

```
gin_blog/
├── config/          # 配置文件
│   └── database.go  # 数据库配置
├── controllers/     # 控制器
│   ├── user_controller.go
│   ├── post_controller.go
│   └── comment_controller.go
├── middleware/      # 中间件
│   ├── auth.go     # JWT认证中间件
│   └── logger.go   # 日志中间件
├── models/         # 数据模型
│   └── models.go
├── routes/         # 路由配置
│   └── routes.go
├── utils/          # 工具函数
│   ├── jwt.go      # JWT工具
│   └── response.go # 响应工具
├── main.go         # 主程序入口
├── go.mod          # Go模块文件
├── go.sum          # 依赖校验文件
└── README.md       # 项目说明
```

## 开发说明

- 所有API都有统一的错误处理和日志记录
- 使用JWT进行身份认证，token有效期为24小时
- 数据库使用GORM的软删除功能
- 支持分页查询，默认每页10条记录
- 密码使用bcrypt加密存储

## 许可证

MIT License