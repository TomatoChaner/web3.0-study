# Go Zero Blog API 测试指南

本指南详细说明如何使用 Postman 测试 Go Zero 博客系统的所有 API 接口。

## 📋 目录

- [环境准备](#环境准备)
- [导入配置](#导入配置)
- [测试流程](#测试流程)
- [API 接口详情](#api-接口详情)
- [错误处理测试](#错误处理测试)
- [常见问题](#常见问题)

## 🚀 环境准备

### 1. 启动服务器

```bash
cd go_zero_blog
go run blog.go
```

服务器将在 `http://localhost:8888` 启动。

### 2. 数据库准备

确保 MySQL 数据库已启动，并且配置文件 `etc/blog.yaml` 中的数据库连接信息正确。

## 📥 导入配置

### 1. 导入 Postman 集合

1. 打开 Postman
2. 点击 "Import" 按钮
3. 选择 `Go_Zero_Blog_API.postman_collection.json` 文件
4. 点击 "Import" 完成导入

### 2. 导入环境配置

1. 在 Postman 中点击右上角的齿轮图标（Manage Environments）
2. 点击 "Import" 按钮
3. 选择 `Go_Zero_Blog_API.postman_environment.json` 文件
4. 点击 "Import" 完成导入
5. 选择 "Go Zero Blog API Environment" 作为当前环境

## 🔄 测试流程

### 推荐测试顺序

1. **用户认证测试**
   - 用户注册
   - 用户登录（自动保存 token）
   - 获取用户信息

2. **文章管理测试**
   - 创建文章（自动保存 post_id）
   - 获取文章列表
   - 获取单篇文章
   - 更新文章
   - 删除文章

3. **评论系统测试**
   - 创建评论（自动保存 comment_id）
   - 获取文章评论列表
   - 删除评论

4. **错误处理测试**
   - 无效登录测试
   - 未授权访问测试
   - 无效文章ID测试

## 📚 API 接口详情

### 用户认证

#### 1. 用户注册
- **方法**: POST
- **路径**: `/api/v1/auth/register`
- **请求体**:
  ```json
  {
    "username": "test@example.com",
    "email": "test@example.com",
    "password": "password123"
  }
  ```

#### 2. 用户登录
- **方法**: POST
- **路径**: `/api/v1/auth/login`
- **请求体**:
  ```json
  {
    "username": "test@example.com",
    "password": "password123"
  }
  ```
- **响应**: 自动保存 `auth_token` 和 `user_id` 到环境变量

#### 3. 获取用户信息
- **方法**: GET
- **路径**: `/api/v1/user/info`
- **认证**: Bearer Token

### 文章管理

#### 1. 创建文章
- **方法**: POST
- **路径**: `/api/v1/posts`
- **认证**: Bearer Token
- **请求体**:
  ```json
  {
    "title": "测试文章标题",
    "content": "文章内容...",
    "summary": "文章摘要"
  }
  ```
- **响应**: 自动保存 `post_id` 到环境变量

#### 2. 获取文章列表
- **方法**: GET
- **路径**: `/api/v1/posts?page=1&limit=10`
- **认证**: Bearer Token

#### 3. 获取单篇文章
- **方法**: GET
- **路径**: `/api/v1/posts/{{post_id}}`
- **认证**: Bearer Token

#### 4. 更新文章
- **方法**: PUT
- **路径**: `/api/v1/posts/{{post_id}}`
- **认证**: Bearer Token
- **请求体**:
  ```json
  {
    "title": "更新后的标题",
    "content": "更新后的内容...",
    "summary": "更新后的摘要"
  }
  ```

#### 5. 删除文章
- **方法**: DELETE
- **路径**: `/api/v1/posts/{{post_id}}`
- **认证**: Bearer Token

### 评论系统

#### 1. 创建评论
- **方法**: POST
- **路径**: `/api/v1/comments`
- **认证**: Bearer Token
- **请求体**:
  ```json
  {
    "post_id": 1,
    "content": "这是一条测试评论"
  }
  ```
- **响应**: 自动保存 `comment_id` 到环境变量

#### 2. 获取文章评论列表
- **方法**: GET
- **路径**: `/api/v1/comments?post_id={{post_id}}`
- **认证**: Bearer Token

#### 3. 删除评论
- **方法**: DELETE
- **路径**: `/api/v1/comments/{{comment_id}}`
- **认证**: Bearer Token

## ❌ 错误处理测试

### 1. 无效登录测试
测试错误的用户名或密码，应返回 400 或 401 状态码。

### 2. 未授权访问测试
不提供 Authorization 头部访问需要认证的接口，应返回 401 状态码。

### 3. 无效文章ID测试
使用不存在的文章ID访问文章，应返回 400 或 404 状态码。

## 🔧 环境变量说明

| 变量名 | 描述 | 示例值 |
|--------|------|--------|
| `base_url` | API服务器地址 | `http://localhost:8888` |
| `test_username` | 测试用户名 | `test@example.com` |
| `test_email` | 测试邮箱 | `test@example.com` |
| `test_password` | 测试密码 | `password123` |
| `auth_token` | JWT认证令牌 | 登录后自动设置 |
| `user_id` | 用户ID | 登录后自动设置 |
| `post_id` | 文章ID | 创建文章后自动设置 |
| `comment_id` | 评论ID | 创建评论后自动设置 |
| `page` | 分页页码 | `1` |
| `limit` | 每页数量 | `10` |

## 🔄 自动化脚本

集合中包含了自动化脚本，可以：

1. **自动保存认证令牌**: 登录成功后自动保存 `auth_token`
2. **自动保存资源ID**: 创建资源后自动保存相应的ID
3. **自动设置用户信息**: 登录后自动保存用户ID

## ❓ 常见问题

### Q1: 登录失败，提示"用户名或密码错误"
**A**: 确保先进行用户注册，或使用已存在的测试账户。

### Q2: 接口返回 401 未授权错误
**A**: 确保已经登录并且 `auth_token` 环境变量已正确设置。

### Q3: 服务器连接失败
**A**: 确保 Go Zero 博客服务器正在运行，并且 `base_url` 环境变量设置正确。

### Q4: 数据库连接错误
**A**: 检查 `etc/blog.yaml` 中的数据库配置，确保 MySQL 服务正在运行。

### Q5: 创建文章失败
**A**: 确保已经登录并且请求体包含必需的字段（title, content, summary）。

## 📝 测试建议

1. **按顺序测试**: 建议按照推荐的测试顺序进行，因为某些接口依赖于前面接口的结果。

2. **检查响应**: 每次请求后检查响应状态码和响应体，确保符合预期。

3. **环境变量**: 利用自动设置的环境变量，避免手动复制粘贴ID。

4. **错误测试**: 不要忽略错误处理测试，这有助于验证系统的健壮性。

5. **清理数据**: 测试完成后可以删除测试数据，保持数据库整洁。

## 🎯 测试覆盖范围

- ✅ 用户注册和登录
- ✅ JWT 认证和授权
- ✅ 文章 CRUD 操作
- ✅ 评论 CRUD 操作
- ✅ 分页查询
- ✅ 权限验证
- ✅ 错误处理
- ✅ 输入验证

通过这个测试集合，您可以全面验证 Go Zero 博客系统的所有功能！