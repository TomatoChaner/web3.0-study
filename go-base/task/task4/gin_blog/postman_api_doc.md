# Gin Blog API - Postman 测试文档

## 环境配置

### 环境变量设置

在 Postman 中创建环境变量：

```
base_url: http://localhost:8080
token: {{登录后获取的JWT令牌}}
user_id: {{登录后获取的用户ID}}
post_id: {{创建文章后获取的文章ID}}
comment_id: {{创建评论后获取的评论ID}}
```

## API 接口测试用例

### 1. 健康检查

**接口**: `GET {{base_url}}/health`

**Headers**: 无

**Body**: 无

**预期响应**:
```json
{
    "code": 200,
    "message": "API is running",
    "data": {
        "status": "healthy",
        "timestamp": "2024-08-29T14:45:45+08:00"
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has correct structure", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('code');
    pm.expect(jsonData).to.have.property('message');
    pm.expect(jsonData).to.have.property('data');
});
```

### 2. 用户注册

**接口**: `POST {{base_url}}/api/v1/auth/register`

**Headers**:
```
Content-Type: application/json
```

**Body** (raw JSON):
```json
{
    "username": "testuser",
    "password": "password123",
    "email": "test@example.com"
}
```

**预期响应**:
```json
{
    "code": 200,
    "message": "用户注册成功",
    "data": {
        "user_id": 1,
        "username": "testuser",
        "email": "test@example.com"
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Registration successful", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data).to.have.property('user_id');
    pm.expect(jsonData.data).to.have.property('username');
    pm.expect(jsonData.data).to.have.property('email');
    
    // 保存用户ID到环境变量
    pm.environment.set("user_id", jsonData.data.user_id);
});
```

### 3. 用户登录

**接口**: `POST {{base_url}}/api/v1/auth/login`

**Headers**:
```
Content-Type: application/json
```

**Body** (raw JSON):
```json
{
    "username": "testuser",
    "password": "password123"
}
```

**预期响应**:
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

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Login successful", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data).to.have.property('token');
    pm.expect(jsonData.data).to.have.property('user_id');
    
    // 保存token到环境变量
    pm.environment.set("token", jsonData.data.token);
    pm.environment.set("user_id", jsonData.data.user_id);
});
```

### 4. 获取用户信息

**接口**: `GET {{base_url}}/api/v1/user/profile`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Body**: 无

**预期响应**:
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "id": 1,
        "username": "testuser",
        "email": "test@example.com",
        "created_at": "2024-08-29T14:45:45+08:00"
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("User profile retrieved", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data).to.have.property('id');
    pm.expect(jsonData.data).to.have.property('username');
    pm.expect(jsonData.data).to.have.property('email');
});
```

### 5. 创建文章

**接口**: `POST {{base_url}}/api/v1/posts`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body** (raw JSON):
```json
{
    "title": "我的第一篇博客文章",
    "content": "这是一篇测试文章的内容，包含了丰富的文本信息。文章内容可以很长，支持多段落的文本。"
}
```

**预期响应**:
```json
{
    "code": 200,
    "message": "文章创建成功",
    "data": {
        "id": 1,
        "title": "我的第一篇博客文章",
        "content": "这是一篇测试文章的内容...",
        "user_id": 1,
        "created_at": "2024-08-29T14:45:45+08:00",
        "updated_at": "2024-08-29T14:45:45+08:00"
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Post created successfully", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data).to.have.property('id');
    pm.expect(jsonData.data).to.have.property('title');
    pm.expect(jsonData.data).to.have.property('content');
    
    // 保存文章ID到环境变量
    pm.environment.set("post_id", jsonData.data.id);
});
```

### 6. 获取文章列表

**接口**: `GET {{base_url}}/api/v1/posts?page=1&page_size=10`

**Headers**: 无

**Body**: 无

**预期响应**:
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "total": 1,
        "page": 1,
        "page_size": 10,
        "data": [
            {
                "id": 1,
                "title": "我的第一篇博客文章",
                "content": "这是一篇测试文章的内容...",
                "user_id": 1,
                "username": "testuser",
                "created_at": "2024-08-29T14:45:45+08:00",
                "updated_at": "2024-08-29T14:45:45+08:00"
            }
        ]
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Posts list retrieved", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data).to.have.property('total');
    pm.expect(jsonData.data).to.have.property('page');
    pm.expect(jsonData.data).to.have.property('page_size');
    pm.expect(jsonData.data).to.have.property('data');
    pm.expect(jsonData.data.data).to.be.an('array');
});
```

### 7. 获取单个文章

**接口**: `GET {{base_url}}/api/v1/posts/{{post_id}}`

**Headers**: 无

**Body**: 无

**预期响应**:
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "id": 1,
        "title": "我的第一篇博客文章",
        "content": "这是一篇测试文章的内容...",
        "user_id": 1,
        "username": "testuser",
        "created_at": "2024-08-29T14:45:45+08:00",
        "updated_at": "2024-08-29T14:45:45+08:00"
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Post retrieved successfully", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data).to.have.property('id');
    pm.expect(jsonData.data).to.have.property('title');
    pm.expect(jsonData.data).to.have.property('content');
    pm.expect(jsonData.data).to.have.property('username');
});
```

### 8. 更新文章

**接口**: `PUT {{base_url}}/api/v1/posts/{{post_id}}`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body** (raw JSON):
```json
{
    "title": "更新后的文章标题",
    "content": "这是更新后的文章内容，包含了新的信息和修改。"
}
```

**预期响应**:
```json
{
    "code": 200,
    "message": "文章更新成功",
    "data": {
        "id": 1,
        "title": "更新后的文章标题",
        "content": "这是更新后的文章内容...",
        "user_id": 1,
        "created_at": "2024-08-29T14:45:45+08:00",
        "updated_at": "2024-08-29T14:46:45+08:00"
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Post updated successfully", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data.title).to.eql("更新后的文章标题");
    pm.expect(jsonData.data.content).to.include("更新后的文章内容");
});
```

### 9. 创建评论

**接口**: `POST {{base_url}}/api/v1/comments`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body** (raw JSON):
```json
{
    "content": "这是一条测试评论，对文章内容进行了评价和讨论。",
    "post_id": {{post_id}}
}
```

**预期响应**:
```json
{
    "code": 200,
    "message": "评论创建成功",
    "data": {
        "id": 1,
        "content": "这是一条测试评论...",
        "user_id": 1,
        "post_id": 1,
        "username": "testuser",
        "created_at": "2024-08-29T14:47:45+08:00",
        "updated_at": "2024-08-29T14:47:45+08:00"
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Comment created successfully", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data).to.have.property('id');
    pm.expect(jsonData.data).to.have.property('content');
    pm.expect(jsonData.data).to.have.property('post_id');
    
    // 保存评论ID到环境变量
    pm.environment.set("comment_id", jsonData.data.id);
});
```

### 10. 获取文章评论

**接口**: `GET {{base_url}}/api/v1/comments/post/{{post_id}}?page=1&page_size=10`

**Headers**: 无

**Body**: 无

**预期响应**:
```json
{
    "code": 200,
    "message": "success",
    "data": {
        "total": 1,
        "page": 1,
        "page_size": 10,
        "data": [
            {
                "id": 1,
                "content": "这是一条测试评论...",
                "user_id": 1,
                "post_id": 1,
                "username": "testuser",
                "created_at": "2024-08-29T14:47:45+08:00",
                "updated_at": "2024-08-29T14:47:45+08:00"
            }
        ]
    }
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Comments retrieved successfully", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.data).to.have.property('total');
    pm.expect(jsonData.data).to.have.property('data');
    pm.expect(jsonData.data.data).to.be.an('array');
});
```

### 11. 删除评论

**接口**: `DELETE {{base_url}}/api/v1/comments/{{comment_id}}`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Body**: 无

**预期响应**:
```json
{
    "code": 200,
    "message": "评论删除成功"
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Comment deleted successfully", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.message).to.include("删除成功");
});
```

### 12. 删除文章

**接口**: `DELETE {{base_url}}/api/v1/posts/{{post_id}}`

**Headers**:
```
Authorization: Bearer {{token}}
```

**Body**: 无

**预期响应**:
```json
{
    "code": 200,
    "message": "文章删除成功"
}
```

**测试脚本**:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Post deleted successfully", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.code).to.eql(200);
    pm.expect(jsonData.message).to.include("删除成功");
});
```

## 错误测试用例

### 1. 未授权访问测试

**接口**: `GET {{base_url}}/api/v1/user/profile`

**Headers**: 无 (不提供Authorization)

**预期响应**:
```json
{
    "code": 401,
    "message": "未提供认证令牌"
}
```

### 2. 无效令牌测试

**接口**: `GET {{base_url}}/api/v1/user/profile`

**Headers**:
```
Authorization: Bearer invalid_token
```

**预期响应**:
```json
{
    "code": 401,
    "message": "无效的认证令牌"
}
```

### 3. 重复注册测试

**接口**: `POST {{base_url}}/api/v1/auth/register`

**Body** (使用已存在的用户名):
```json
{
    "username": "testuser",
    "password": "password123",
    "email": "test2@example.com"
}
```

**预期响应**:
```json
{
    "code": 400,
    "message": "用户名已存在"
}
```

### 4. 错误登录测试

**接口**: `POST {{base_url}}/api/v1/auth/login`

**Body** (错误密码):
```json
{
    "username": "testuser",
    "password": "wrongpassword"
}
```

**预期响应**:
```json
{
    "code": 401,
    "message": "用户名或密码错误"
}
```

### 5. 访问不存在的文章

**接口**: `GET {{base_url}}/api/v1/posts/999`

**预期响应**:
```json
{
    "code": 404,
    "message": "文章不存在"
}
```

## 测试流程建议

### 完整测试流程

1. **健康检查** - 确保服务正常运行
2. **用户注册** - 创建测试用户
3. **用户登录** - 获取认证令牌
4. **获取用户信息** - 验证认证功能
5. **创建文章** - 测试文章创建功能
6. **获取文章列表** - 验证文章列表功能
7. **获取单个文章** - 验证文章详情功能
8. **更新文章** - 测试文章更新功能
9. **创建评论** - 测试评论功能
10. **获取文章评论** - 验证评论列表功能
11. **删除评论** - 测试评论删除功能
12. **删除文章** - 测试文章删除功能
13. **错误测试** - 验证各种错误情况

### 批量测试脚本

可以在 Postman 的 Collection 级别添加以下预请求脚本：

```javascript
// 设置基础URL
pm.globals.set("base_url", "http://localhost:8080");

// 生成随机测试数据
const randomString = Math.random().toString(36).substring(7);
pm.globals.set("random_string", randomString);
pm.globals.set("test_username", "testuser_" + randomString);
pm.globals.set("test_email", "test_" + randomString + "@example.com");
```

### 环境清理脚本

在测试完成后，可以添加清理脚本：

```javascript
// 清理环境变量
pm.environment.unset("token");
pm.environment.unset("user_id");
pm.environment.unset("post_id");
pm.environment.unset("comment_id");
```

## 注意事项

1. **测试顺序**: 某些测试用例依赖于前面的测试结果（如需要先登录获取token）
2. **数据清理**: 建议在测试环境中定期清理测试数据
3. **并发测试**: 注意多用户并发访问的情况
4. **性能测试**: 可以使用 Postman 的 Runner 功能进行批量测试
5. **环境隔离**: 建议使用独立的测试数据库

## 导入到 Postman

1. 打开 Postman
2. 点击 "Import" 按钮
3. 选择 "Raw text" 选项
4. 将上述接口信息按照 Postman Collection 格式整理后导入
5. 设置环境变量
6. 开始测试

这份文档提供了完整的 API 测试用例，可以帮助验证博客系统的所有功能是否正常工作。