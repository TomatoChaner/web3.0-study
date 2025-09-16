# 🌸 个人博客系统

> 基于 Next.js 14 + Supabase 构建的现代化个人博客系统，风格清新，结构简单

[![Next.js](https://img.shields.io/badge/Next.js-14-black?style=flat-square&logo=next.js)](https://nextjs.org/)
[![Supabase](https://img.shields.io/badge/Supabase-Database-green?style=flat-square&logo=supabase)](https://supabase.com/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue?style=flat-square&logo=typescript)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-CSS-38B2AC?style=flat-square&logo=tailwind-css)](https://tailwindcss.com/)

## ✨ 项目特色

- 🎨 **清新设计** - 简洁优雅的日系风格界面
- ⚡ **高性能** - 基于 Next.js 14 的 SSG/ISR 技术
- 📱 **响应式** - 完美适配各种设备屏幕
- 🔍 **SEO 友好** - 完整的 SEO 优化和元数据管理
- 📝 **Markdown 支持** - 原生支持 Markdown 文章编写
- 🏷️ **标签系统** - 灵活的文章分类和标签管理
- 💬 **评论功能** - 集成评论系统，支持互动交流

## 🚀 快速开始

### 环境要求

- Node.js 18.0 或更高版本
- npm 或 yarn 包管理器
- Supabase 账户

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd personal-blog
```

2. **安装依赖**
```bash
npm install
# 或
yarn install
```

3. **环境配置**
```bash
# 复制环境变量模板
cp .env.example .env.local

# 编辑环境变量
# NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
# NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. **数据库设置**
```bash
# 运行数据库初始化脚本
npm run db:setup
```

5. **启动开发服务器**
```bash
npm run dev
```

访问 [http://localhost:3000](http://localhost:3000) 查看应用

## 📁 项目结构

```
personal-blog/
├── src/
│   ├── app/                    # Next.js 14 App Router
│   │   ├── api/               # API 路由
│   │   ├── articles/          # 文章相关页面
│   │   ├── globals.css        # 全局样式
│   │   ├── layout.tsx         # 根布局
│   │   └── page.tsx           # 首页
│   ├── components/            # 可复用组件
│   │   ├── layout/           # 布局组件
│   │   └── ui/               # UI 组件
│   ├── lib/                  # 工具库
│   │   ├── api.ts            # API 封装
│   │   ├── supabase.ts       # Supabase 客户端
│   │   └── utils.ts          # 工具函数
│   └── types/                # TypeScript 类型定义
├── public/                   # 静态资源
├── docs/                     # 项目文档
└── scripts/                  # 脚本文件
```

## 🛠️ 技术栈

### 前端技术
- **Next.js 14** - React 全栈框架，支持 SSG/ISR
- **TypeScript** - 类型安全的 JavaScript
- **Tailwind CSS** - 原子化 CSS 框架
- **Framer Motion** - 动画库
- **React Hook Form** - 表单处理
- **SWR** - 数据获取和缓存

### 后端服务
- **Supabase** - 开源的 Firebase 替代方案
  - PostgreSQL 数据库
  - 实时订阅
  - 用户认证
  - 存储服务

### 开发工具
- **ESLint** - 代码规范检查
- **Prettier** - 代码格式化
- **Husky** - Git hooks
- **Vercel** - 部署平台

## 🗄️ 数据库设计

### 核心表结构

```sql
-- 文章表
CREATE TABLE articles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  content TEXT NOT NULL,
  excerpt TEXT,
  featured_image TEXT,
  published BOOLEAN DEFAULT false,
  author_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  published_at TIMESTAMP WITH TIME ZONE,
  view_count INTEGER DEFAULT 0
);

-- 标签表
CREATE TABLE tags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 文章标签关联表
CREATE TABLE article_tags (
  article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (article_id, tag_id)
);

-- 评论表
CREATE TABLE comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
  author_name VARCHAR(100) NOT NULL,
  author_email VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  approved BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## ✨ 核心功能

### 基础功能 (60分)
- ✅ **文章列表页** - 支持分页、搜索和筛选
- ✅ **文章详情页** - Markdown 渲染、代码高亮
- ✅ **文章创建页面** - 富文本编辑器、实时预览
- ✅ **基础 SEO 优化** - 元数据、结构化数据
- ✅ **ISR 增量静态再生** - 性能优化

### 进阶功能 (40分)
- ✅ **文章编辑/删除** - 完整的 CRUD 操作
- ✅ **Markdown 渲染** - 支持代码高亮、数学公式
- ✅ **标签分类系统** - 灵活的内容组织
- ✅ **评论功能** - 用户互动和反馈
- ✅ **Vercel 部署** - 一键部署到生产环境

## 📱 页面展示

### 首页
- 精选文章展示
- 统计数据概览
- 热门标签云
- 订阅功能

### 文章列表
- 响应式卡片布局
- 搜索和筛选
- 分页导航
- 加载状态

### 文章详情
- Markdown 渲染
- 目录导航
- 相关文章推荐
- 评论系统

### 文章编辑
- 实时预览
- 标签管理
- 图片上传
- 草稿保存

## 🚀 部署指南

### Vercel 部署

1. **连接 GitHub**
```bash
# 推送代码到 GitHub
git add .
git commit -m "Initial commit"
git push origin main
```

2. **Vercel 配置**
- 登录 [Vercel](https://vercel.com)
- 导入 GitHub 仓库
- 配置环境变量
- 部署应用

3. **环境变量设置**
```bash
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 自定义域名
- 在 Vercel 项目设置中添加自定义域名
- 配置 DNS 记录
- 启用 HTTPS

## 📊 性能优化

### 核心指标
- **Lighthouse 评分** ≥ 90
- **首屏加载时间** < 2s
- **交互响应时间** < 100ms

### 优化策略
- 静态生成 (SSG)
- 增量静态再生 (ISR)
- 图片优化和懒加载
- 代码分割和预加载
- CDN 缓存策略

## 🔧 开发脚本

```bash
# 开发
npm run dev          # 启动开发服务器
npm run build        # 构建生产版本
npm run start        # 启动生产服务器

# 代码质量
npm run lint         # ESLint 检查
npm run lint:fix     # 自动修复 ESLint 问题
npm run type-check   # TypeScript 类型检查

# 数据库
npm run db:setup     # 初始化数据库
npm run db:seed      # 填充示例数据
npm run db:reset     # 重置数据库

# 部署
npm run deploy       # 部署到 Vercel
```

## 📚 开发指南

### 代码规范
- 使用 TypeScript 进行类型安全开发
- 遵循 ESLint 和 Prettier 配置
- 组件采用函数式编程风格
- 使用 Tailwind CSS 进行样式开发

### 提交规范
```bash
feat: 新功能
fix: 修复问题
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建过程或辅助工具的变动
```

### 分支管理
- `main` - 主分支，用于生产环境
- `develop` - 开发分支
- `feature/*` - 功能分支
- `hotfix/*` - 热修复分支

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [Next.js](https://nextjs.org/) - React 全栈框架
- [Supabase](https://supabase.com/) - 开源后端服务
- [Tailwind CSS](https://tailwindcss.com/) - CSS 框架
- [Vercel](https://vercel.com/) - 部署平台

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 📧 Email: your-email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/your-username/personal-blog/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/your-username/personal-blog/discussions)

---

⭐ 如果这个项目对你有帮助，请给它一个星标！