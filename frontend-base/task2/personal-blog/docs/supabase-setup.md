# Supabase 配置指南

本指南将帮助你从零开始配置 Supabase 数据库服务。

## 1. 注册 Supabase 账号

### 步骤 1：访问 Supabase 官网

1. 打开浏览器，访问 [https://supabase.com](https://supabase.com)
2. 点击右上角的 "Start your project" 或 "Sign up" 按钮

### 步骤 2：注册账号

1. 可以选择以下方式之一注册：
   - 使用 GitHub 账号登录（推荐）
   - 使用 Google 账号登录
   - 使用邮箱注册
2. 按照提示完成注册流程

## 2. 创建新项目

### 步骤 1：创建组织（如果是首次使用）

1. 登录后，系统会提示创建组织
2. 输入组织名称（可以使用你的用户名）
3. 点击 "Create organization"

### 步骤 2：创建项目

1. 在控制台页面，点击 "New project" 按钮
2. 填写项目信息：
   - **Name**: `personal-blog`（项目名称）
   - **Database Password**: 设置一个强密码（请记住这个密码）root
   - **Region**: 选择 `Northeast Asia (Tokyo)` 或 `Southeast Asia (Singapore)`（距离中国较近）
3. 点击 "Create new project"
4. 等待项目创建完成（通常需要1-2分钟）

## 3. 获取项目配置信息

### 步骤 1：获取 API 密钥

1. 项目创建完成后，进入项目控制台
2. 在左侧菜单中点击 "Settings"（设置）
3. 点击 "API" 选项卡
4. 你会看到以下重要信息：
   - **Project URL**: 形如 `https://xxxxx.supabase.co`
   - **anon public**: 匿名公钥（用于客户端）
   - **service_role**: 服务角色密钥（用于服务端，保密）

### 步骤 2：复制配置信息

请复制以下信息，稍后会用到：

```
Project URL: https://your-project-id.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Service Role Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 4. 配置本地环境变量

### 步骤 1：创建环境变量文件

1. 在项目根目录下，复制 `.env.local.example` 文件
2. 重命名为 `.env.local`

```bash
cp .env.local.example .env.local
```

### 步骤 2：填写配置信息

打开 `.env.local` 文件，填入你的 Supabase 项目信息：

```env
# Supabase 配置
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# 网站基础 URL
NEXT_PUBLIC_SITE_URL=http://localhost:3000

# 管理员邮箱（用于后台管理权限）
ADMIN_EMAIL=your-email@example.com
```

**重要提示：**

- 将 `your-project-id` 替换为你的实际项目ID
- 将 `your_anon_key_here` 替换为你的匿名公钥
- 将 `your_service_role_key_here` 替换为你的服务角色密钥
- 将 `your-email@example.com` 替换为你的邮箱（用于管理员权限）

## 5. 初始化数据库

### 步骤 1：运行数据库脚本

1. 在 Supabase 控制台中，点击左侧菜单的 "SQL Editor"
2. 点击 "New query" 创建新查询
3. 复制 `scripts/setup-db.sql` 文件中的所有内容
4. 粘贴到 SQL 编辑器中
5. 点击 "Run" 按钮执行脚本
6. 等待执行完成，应该会看到 "Database setup completed successfully!" 消息

### 步骤 2：验证数据库表

1. 在左侧菜单中点击 "Table Editor"
2. 你应该能看到以下表：
   - `articles`（文章表）
   - `tags`（标签表）
   - `article_tags`（文章标签关联表）
   - `comments`（评论表）

## 6. 配置认证设置

### 步骤 1：配置认证提供商

1. 在 Supabase 控制台中，点击 "Authentication"
2. 点击 "Settings" 选项卡
3. 在 "Site URL" 中填入：`http://localhost:3000`
4. 在 "Redirect URLs" 中添加：
   - `http://localhost:3000/auth/callback`
   - `http://localhost:3000/auth/reset-password`

### 步骤 2：启用邮箱认证

1. 在 "Providers" 选项卡中
2. 确保 "Email" 提供商已启用
3. 可以根据需要启用其他提供商（如 Google、GitHub 等）

## 7. 测试连接

### 步骤 1：启动开发服务器

```bash
npm run dev
```

### 步骤 2：验证配置

1. 打开浏览器访问 `http://localhost:3000`
2. 检查浏览器控制台是否有错误
3. 如果没有错误，说明 Supabase 配置成功

## 8. 常见问题解决

### 问题 1：连接失败

**可能原因：**

- URL 或密钥配置错误
- 网络连接问题

**解决方案：**

1. 检查 `.env.local` 文件中的配置是否正确
2. 确保没有多余的空格或引号
3. 重启开发服务器

### 问题 2：认证失败

**可能原因：**

- 认证设置配置错误
- 重定向 URL 不匹配

**解决方案：**

1. 检查 Supabase 控制台中的认证设置
2. 确保重定向 URL 配置正确

### 问题 3：数据库操作失败

**可能原因：**

- 数据库表未创建
- 权限设置问题

**解决方案：**

1. 重新运行 `setup-db.sql` 脚本
2. 检查行级安全策略设置

## 9. 下一步

配置完成后，你可以：

1. 开始开发博客功能
2. 创建文章管理页面
3. 实现用户认证功能
4. 添加评论系统

## 10. 有用的资源

- [Supabase 官方文档](https://supabase.com/docs)
- [Supabase JavaScript 客户端文档](https://supabase.com/docs/reference/javascript)
- [Next.js 与 Supabase 集成指南](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs)

---

如果在配置过程中遇到问题，请检查：

1. 网络连接是否正常
2. 配置信息是否正确
3. 环境变量文件是否保存
4. 开发服务器是否重启

配置成功后，你就可以开始使用 Supabase 作为你的博客系统后端了！
