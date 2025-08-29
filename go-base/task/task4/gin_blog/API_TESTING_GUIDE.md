# Gin Blog API 测试指南

## 概述

本文档提供了完整的 Gin Blog API 测试指南，包括 Postman 测试和命令行测试两种方式。

## 文件说明

### 测试相关文件

1. **postman_api_doc.md** - 详细的 API 文档和测试用例说明
2. **Gin_Blog_API.postman_collection.json** - Postman 测试集合文件
3. **Gin_Blog_API.postman_environment.json** - Postman 环境配置文件
4. **test_api.sh** - 命令行测试脚本
5. **API_TESTING_GUIDE.md** - 本测试指南

## 方法一：使用 Postman 测试

### 1. 导入测试集合

1. 打开 Postman
2. 点击 "Import" 按钮
3. 选择 "File" 选项
4. 导入 `Gin_Blog_API.postman_collection.json` 文件
5. 导入 `Gin_Blog_API.postman_environment.json` 文件

### 2. 设置环境

1. 在 Postman 右上角选择 "Gin Blog API Environment" 环境
2. 确保 `base_url` 设置为 `http://localhost:8080`
3. 其他变量会在测试过程中自动设置

### 3. 运行测试

#### 单个测试
- 选择任意接口，点击 "Send" 按钮
- 查看响应结果和测试结果

#### 批量测试
1. 右键点击 "Gin Blog API" 集合
2. 选择 "Run collection"
3. 在 Collection Runner 中点击 "Run Gin Blog API"
4. 查看测试结果报告

### 4. 测试顺序建议

按以下顺序执行测试以确保依赖关系：

1. 健康检查
2. 用户注册
3. 用户登录（获取 token）
4. 获取用户信息
5. 创建文章
6. 获取文章列表
7. 获取单个文章
8. 更新文章
9. 创建评论
10. 获取文章评论
11. 删除评论
12. 删除文章
13. 错误测试用例

## 方法二：使用命令行测试

### 1. 运行测试脚本

```bash
# 确保服务器正在运行
go run main.go

# 在新终端中运行测试脚本
./test_api.sh
```

### 2. 测试脚本功能

测试脚本会自动执行以下操作：

- ✅ 检查服务器状态
- ✅ 生成随机测试用户数据
- ✅ 执行完整的 API 测试流程
- ✅ 自动提取和使用 token
- ✅ 清理测试数据
- ✅ 显示彩色测试结果

### 3. 手动 curl 测试

如果需要手动测试特定接口：

```bash
# 健康检查
curl -X GET http://localhost:8080/health

# 用户注册
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123","email":"test@example.com"}'

# 用户登录
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'

# 获取用户信息（需要 token）
curl -X GET http://localhost:8080/api/v1/user/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 创建文章（需要 token）
curl -X POST http://localhost:8080/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title":"测试文章","content":"文章内容"}'

# 获取文章列表
curl -X GET "http://localhost:8080/api/v1/posts?page=1&page_size=10"
```

## API 接口列表

### 认证相关

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| GET | `/health` | 健康检查 | 否 |
| POST | `/api/v1/auth/register` | 用户注册 | 否 |
| POST | `/api/v1/auth/login` | 用户登录 | 否 |
| GET | `/api/v1/user/profile` | 获取用户信息 | 是 |

### 文章管理

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| POST | `/api/v1/posts` | 创建文章 | 是 |
| GET | `/api/v1/posts` | 获取文章列表 | 否 |
| GET | `/api/v1/posts/:id` | 获取单个文章 | 否 |
| PUT | `/api/v1/posts/:id` | 更新文章 | 是 |
| DELETE | `/api/v1/posts/:id` | 删除文章 | 是 |

### 评论管理

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| POST | `/api/v1/comments` | 创建评论 | 是 |
| GET | `/api/v1/comments/post/:post_id` | 获取文章评论 | 否 |
| DELETE | `/api/v1/comments/:id` | 删除评论 | 是 |

## 响应格式

### 成功响应

```json
{
  "code": 200,
  "message": "success",
  "data": {
    // 具体数据
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

### 分页响应

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 100,
    "page": 1,
    "page_size": 10,
    "data": [
      // 数据列表
    ]
  }
}
```

## 常见状态码

| 状态码 | 描述 |
|--------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误 |
| 401 | 未授权访问 |
| 403 | 禁止访问 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

## 测试数据示例

### 用户数据

```json
{
  "username": "testuser",
  "password": "password123",
  "email": "test@example.com"
}
```

### 文章数据

```json
{
  "title": "我的第一篇博客文章",
  "content": "这是一篇测试文章的内容，包含了丰富的文本信息。"
}
```

### 评论数据

```json
{
  "content": "这是一条测试评论，对文章内容进行了评价。",
  "post_id": 1
}
```

## 故障排除

### 常见问题

1. **服务器未启动**
   ```bash
   # 启动服务器
   go run main.go
   ```

2. **数据库连接失败**
   ```bash
   # 检查 MySQL 服务
   brew services start mysql
   
   # 创建数据库
   mysql -u root -p -e "CREATE DATABASE gin_blog CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
   ```

3. **端口被占用**
   ```bash
   # 查看端口占用
   lsof -i :8080
   
   # 杀死占用进程
   kill -9 PID
   ```

4. **Token 过期**
   - 重新登录获取新的 token
   - 检查 JWT 配置中的过期时间

5. **权限不足**
   - 确保请求头包含正确的 Authorization
   - 检查 token 格式：`Bearer YOUR_TOKEN`

### 调试技巧

1. **查看服务器日志**
   - 服务器控制台会显示详细的请求日志
   - 检查错误信息和堆栈跟踪

2. **使用 Postman Console**
   - 在 Postman 中打开 Console 查看详细请求信息
   - 检查请求头、请求体和响应

3. **检查环境变量**
   - 确保 Postman 环境变量设置正确
   - 验证 token 和 ID 是否正确保存

## 性能测试

### 使用 Postman Runner

1. 设置迭代次数（如 100 次）
2. 设置延迟时间（如 100ms）
3. 运行集合并查看性能报告

### 使用 Apache Bench

```bash
# 测试健康检查接口
ab -n 1000 -c 10 http://localhost:8080/health

# 测试文章列表接口
ab -n 1000 -c 10 "http://localhost:8080/api/v1/posts?page=1&page_size=10"
```

## 安全测试

### 测试要点

1. **认证测试**
   - 未授权访问受保护的接口
   - 使用无效或过期的 token
   - 使用错误格式的 token

2. **输入验证测试**
   - 发送空数据
   - 发送超长数据
   - 发送特殊字符和 SQL 注入尝试

3. **权限测试**
   - 尝试访问其他用户的资源
   - 尝试执行未授权的操作

## 总结

本测试指南提供了完整的 API 测试方案，包括：

- ✅ Postman 集合和环境配置
- ✅ 自动化测试脚本
- ✅ 手动测试命令
- ✅ 详细的接口文档
- ✅ 故障排除指南
- ✅ 性能和安全测试建议

通过这些工具和文档，您可以全面测试 Gin Blog API 的功能、性能和安全性。