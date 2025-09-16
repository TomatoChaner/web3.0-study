-- 插入作者数据
INSERT INTO authors (id, name, email, bio, avatar, website, social_links) VALUES
(
  '550e8400-e29b-41d4-a716-446655440000',
  '张三',
  'zhangsan@example.com',
  '全栈开发工程师，专注于 React、Node.js 和云原生技术。热爱分享技术心得，致力于构建更好的用户体验。',
  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
  'https://zhangsan.dev',
  '{"github": "https://github.com/zhangsan", "twitter": "https://twitter.com/zhangsan", "linkedin": "https://linkedin.com/in/zhangsan"}'
);

-- 插入标签数据
INSERT INTO tags (name, slug, description, color) VALUES
('React', 'react', 'React.js 相关技术文章', 'bg-blue-100 text-blue-800'),
('Next.js', 'nextjs', 'Next.js 框架相关内容', 'bg-gray-100 text-gray-800'),
('TypeScript', 'typescript', 'TypeScript 开发技巧', 'bg-blue-100 text-blue-800'),
('JavaScript', 'javascript', 'JavaScript 基础与进阶', 'bg-yellow-100 text-yellow-800'),
('CSS', 'css', 'CSS 样式与布局技巧', 'bg-pink-100 text-pink-800'),
('Node.js', 'nodejs', 'Node.js 后端开发', 'bg-green-100 text-green-800'),
('数据库', 'database', '数据库设计与优化', 'bg-purple-100 text-purple-800'),
('性能优化', 'performance', 'Web 性能优化技巧', 'bg-red-100 text-red-800'),
('工具', 'tools', '开发工具与效率提升', 'bg-indigo-100 text-indigo-800'),
('教程', 'tutorial', '技术教程与指南', 'bg-green-100 text-green-800');

-- 插入文章数据
INSERT INTO articles (id, title, content, excerpt, slug, cover_image, published, featured, view_count, like_count, reading_time, author_id) VALUES
(
  '550e8400-e29b-41d4-a716-446655440001',
  'Next.js 14 App Router 完全指南',
  '# Next.js 14 App Router 完全指南

Next.js 14 带来了许多令人兴奋的新特性，其中 App Router 是最重要的更新之一。本文将深入探讨 App Router 的核心概念和最佳实践。

## 什么是 App Router？

App Router 是 Next.js 13 引入的新路由系统，在 Next.js 14 中得到了进一步完善。它基于 React Server Components，提供了更强大的路由功能。

## 核心特性

### 1. 文件系统路由
App Router 使用文件系统来定义路由，每个文件夹代表一个路由段。

```typescript
app/
  page.tsx          // /
  about/
    page.tsx        // /about
  blog/
    page.tsx        // /blog
    [slug]/
      page.tsx      // /blog/[slug]
```

### 2. 布局系统
布局允许你在多个页面之间共享 UI。

```typescript
// app/layout.tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh">
      <body>
        <nav>导航栏</nav>
        {children}
        <footer>页脚</footer>
      </body>
    </html>
  )
}
```

### 3. 服务器组件
默认情况下，App Router 中的组件都是服务器组件。

```typescript
// app/page.tsx
async function getData() {
  const res = await fetch("https://api.example.com/data")
  return res.json()
}

export default async function Page() {
  const data = await getData()
  return <div>{data.title}</div>
}
```

## 最佳实践

1. **合理使用服务器组件和客户端组件**
2. **优化数据获取策略**
3. **正确处理错误和加载状态**

## 总结

App Router 为 Next.js 应用带来了更好的性能和开发体验。通过合理使用其特性，我们可以构建更快、更可维护的应用。',
  'Next.js 14 App Router 是最重要的更新之一，本文深入探讨其核心概念和最佳实践，包括文件系统路由、布局系统、服务器组件等关键特性。',
  'nextjs-14-app-router-guide',
  'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&h=400&fit=crop',
  true,
  true,
  1250,
  89,
  8,
  '550e8400-e29b-41d4-a716-446655440000'
),
(
  '550e8400-e29b-41d4-a716-446655440002',
  'React Server Components 深度解析',
  '# React Server Components 深度解析

React Server Components (RSC) 是 React 18 引入的革命性特性，它改变了我们构建 React 应用的方式。

## 什么是 Server Components？

Server Components 是在服务器上渲染的 React 组件，它们可以直接访问后端资源，如数据库、文件系统等。

## 核心优势

### 1. 零客户端 JavaScript
Server Components 不会向客户端发送任何 JavaScript 代码。

### 2. 直接访问后端资源
可以直接在组件中访问数据库、API 等后端资源。

```typescript
// 服务器组件
async function UserProfile({ userId }: { userId: string }) {
  // 直接访问数据库
  const user = await db.user.findUnique({
    where: { id: userId }
  })
  
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  )
}
```

### 3. 自动代码分割
每个 Server Component 都会自动进行代码分割。

## 与客户端组件的区别

| 特性 | Server Components | Client Components |
|------|------------------|-------------------|
| 渲染位置 | 服务器 | 客户端 |
| JavaScript 包大小 | 0 | 包含在包中 |
| 数据获取 | 直接访问 | 通过 API |
| 交互性 | 无 | 完全支持 |

## 使用场景

1. **数据展示组件**
2. **静态内容**
3. **SEO 敏感页面**

## 注意事项

1. 不能使用浏览器 API
2. 不能使用事件处理器
3. 不能使用 useState、useEffect 等 Hook

## 总结

React Server Components 为我们提供了新的架构模式，通过合理使用可以显著提升应用性能。',
  'React Server Components 是 React 18 的革命性特性，本文深度解析其核心概念、优势和使用场景，帮助开发者更好地理解和应用这一新技术。',
  'react-server-components-deep-dive',
  'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=800&h=400&fit=crop',
  true,
  true,
  980,
  67,
  6,
  '550e8400-e29b-41d4-a716-446655440000'
),
(
  '550e8400-e29b-41d4-a716-446655440003',
  'TypeScript 高级类型技巧',
  '# TypeScript 高级类型技巧

TypeScript 的类型系统非常强大，掌握高级类型技巧可以让我们写出更安全、更优雅的代码。

## 1. 条件类型

条件类型允许我们根据条件选择类型。

```typescript
type IsArray<T> = T extends any[] ? true : false

type A = IsArray<string[]> // true
type B = IsArray<string>   // false
```

## 2. 映射类型

映射类型可以基于现有类型创建新类型。

```typescript
type Partial<T> = {
  [P in keyof T]?: T[P]
}

type Required<T> = {
  [P in keyof T]-?: T[P]
}
```

## 3. 模板字面量类型

TypeScript 4.1 引入了模板字面量类型。

```typescript
type EventName<T extends string> = `on${Capitalize<T>}`

type ClickEvent = EventName<"click"> // "onClick"
type HoverEvent = EventName<"hover"> // "onHover"
```

## 4. 递归类型

TypeScript 支持递归类型定义。

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object 
    ? DeepReadonly<T[P]> 
    : T[P]
}
```

## 5. 工具类型

TypeScript 提供了许多内置工具类型。

```typescript
// Pick - 选择属性
type UserInfo = Pick<User, "name" | "email">

// Omit - 排除属性
type CreateUser = Omit<User, "id" | "createdAt">

// Record - 创建记录类型
type StatusMap = Record<string, boolean>
```

## 实际应用

### API 响应类型
```typescript
type ApiResponse<T> = {
  data: T
  success: boolean
  message?: string
}

type UserResponse = ApiResponse<User>
type UsersResponse = ApiResponse<User[]>
```

### 表单验证
```typescript
type ValidationRule<T> = {
  [K in keyof T]: (value: T[K]) => string | undefined
}

const userValidation: ValidationRule<User> = {
  name: (value) => value.length > 0 ? undefined : "姓名不能为空",
  email: (value) => /\S+@\S+\.\S+/.test(value) ? undefined : "邮箱格式错误"
}
```

## 总结

掌握 TypeScript 高级类型技巧可以让我们构建更健壮的类型系统，提高代码质量和开发效率。',
  'TypeScript 的类型系统非常强大，本文介绍条件类型、映射类型、模板字面量类型等高级技巧，帮助开发者构建更健壮的类型系统。',
  'typescript-advanced-types',
  'https://images.unsplash.com/photo-1516116216624-53e697fedbea?w=800&h=400&fit=crop',
  true,
  false,
  756,
  45,
  5,
  '550e8400-e29b-41d4-a716-446655440000'
),
(
  '550e8400-e29b-41d4-a716-446655440004',
  'CSS Grid 布局完全指南',
  '# CSS Grid 布局完全指南

CSS Grid 是现代 Web 布局的强大工具，它提供了二维布局系统，让复杂布局变得简单。

## 基础概念

### Grid Container 和 Grid Item
```css
.container {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  grid-template-rows: 100px 200px;
  gap: 20px;
}
```

### 网格线和网格轨道
Grid 由网格线组成，网格线之间的空间称为网格轨道。

## 核心属性

### 1. grid-template-columns/rows
定义网格的列和行。

```css
.grid {
  /* 固定尺寸 */
  grid-template-columns: 200px 200px 200px;
  
  /* 分数单位 */
  grid-template-columns: 1fr 2fr 1fr;
  
  /* 重复函数 */
  grid-template-columns: repeat(3, 1fr);
  
  /* 自动填充 */
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
}
```

### 2. grid-area
定义网格项目的位置。

```css
.item {
  grid-area: 1 / 1 / 3 / 3; /* row-start / col-start / row-end / col-end */
}
```

### 3. grid-template-areas
使用命名区域定义布局。

```css
.container {
  grid-template-areas:
    "header header header"
    "sidebar main main"
    "footer footer footer";
}

.header { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main { grid-area: main; }
.footer { grid-area: footer; }
```

## 实际应用

### 响应式卡片布局
```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  padding: 2rem;
}
```

### 圣杯布局
```css
.holy-grail {
  display: grid;
  grid-template-areas:
    "header header header"
    "nav main aside"
    "footer footer footer";
  grid-template-rows: auto 1fr auto;
  grid-template-columns: 200px 1fr 200px;
  min-height: 100vh;
}
```

## 与 Flexbox 的对比

| 特性 | Grid | Flexbox |
|------|------|---------|
| 维度 | 二维 | 一维 |
| 用途 | 页面布局 | 组件布局 |
| 对齐 | 强大的对齐选项 | 灵活的对齐 |

## 浏览器支持

现代浏览器都支持 CSS Grid，IE 11 需要使用前缀。

## 总结

CSS Grid 是现代布局的首选方案，它简化了复杂布局的实现，提供了强大而灵活的布局能力。',
  'CSS Grid 是现代 Web 布局的强大工具，本文详细介绍其核心概念、属性和实际应用，帮助开发者掌握二维布局系统。',
  'css-grid-complete-guide',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=400&fit=crop',
  true,
  false,
  623,
  38,
  4,
  '550e8400-e29b-41d4-a716-446655440000'
),
(
  '550e8400-e29b-41d4-a716-446655440005',
  'Node.js 性能优化实战',
  '# Node.js 性能优化实战

Node.js 应用的性能优化是一个系统性工程，本文将从多个维度介绍实用的优化技巧。

## 1. 事件循环优化

### 避免阻塞事件循环
```javascript
// 错误示例
function heavyComputation() {
  let result = 0
  for (let i = 0; i < 10000000; i++) {
    result += i
  }
  return result
}

// 优化示例
function heavyComputationAsync() {
  return new Promise((resolve) => {
    setImmediate(() => {
      let result = 0
      for (let i = 0; i < 10000000; i++) {
        result += i
      }
      resolve(result)
    })
  })
}
```

### 使用 Worker Threads
```javascript
const { Worker, isMainThread, parentPort } = require("worker_threads")

if (isMainThread) {
  const worker = new Worker(__filename)
  worker.postMessage(1000000)
  worker.on("message", (result) => {
    console.log("计算结果:", result)
  })
} else {
  parentPort.on("message", (num) => {
    const result = fibonacci(num)
    parentPort.postMessage(result)
  })
}
```

## 2. 内存管理

### 监控内存使用
```javascript
function logMemoryUsage() {
  const used = process.memoryUsage()
  console.log({
    rss: Math.round(used.rss / 1024 / 1024) + " MB",
    heapTotal: Math.round(used.heapTotal / 1024 / 1024) + " MB",
    heapUsed: Math.round(used.heapUsed / 1024 / 1024) + " MB",
    external: Math.round(used.external / 1024 / 1024) + " MB"
  })
}
```

### 避免内存泄漏
```javascript
// 正确清理事件监听器
class DataProcessor extends EventEmitter {
  constructor() {
    super()
    this.timer = setInterval(() => {
      this.emit("data", new Date())
    }, 1000)
  }
  
  destroy() {
    clearInterval(this.timer)
    this.removeAllListeners()
  }
}
```

## 3. 数据库优化

### 连接池管理
```javascript
const mysql = require("mysql2/promise")

const pool = mysql.createPool({
  host: "localhost",
  user: "root",
  password: "password",
  database: "mydb",
  connectionLimit: 10,
  queueLimit: 0
})

async function getUser(id) {
  const [rows] = await pool.execute(
    "SELECT * FROM users WHERE id = ?",
    [id]
  )
  return rows[0]
}
```

### 查询优化
```javascript
// 使用索引
// CREATE INDEX idx_user_email ON users(email);

// 批量操作
async function createUsers(users) {
  const values = users.map(user => [user.name, user.email])
  await pool.execute(
    "INSERT INTO users (name, email) VALUES ?",
    [values]
  )
}
```

## 4. 缓存策略

### Redis 缓存
```javascript
const redis = require("redis")
const client = redis.createClient()

async function getCachedUser(id) {
  const cached = await client.get(`user:${id}`)
  if (cached) {
    return JSON.parse(cached)
  }
  
  const user = await getUserFromDB(id)
  await client.setex(`user:${id}`, 3600, JSON.stringify(user))
  return user
}
```

### 内存缓存
```javascript
const NodeCache = require("node-cache")
const cache = new NodeCache({ stdTTL: 600 })

function getCachedData(key, fetchFunction) {
  let data = cache.get(key)
  if (!data) {
    data = fetchFunction()
    cache.set(key, data)
  }
  return data
}
```

## 5. HTTP 优化

### 启用压缩
```javascript
const compression = require("compression")
app.use(compression())
```

### 设置缓存头
```javascript
app.use(express.static("public", {
  maxAge: "1d",
  etag: true
}))
```

## 6. 监控和分析

### 使用 Clinic.js
```bash
npm install -g clinic
clinic doctor -- node app.js
clinic flame -- node app.js
```

### APM 工具
```javascript
const newrelic = require("newrelic")
// 或者
const apm = require("elastic-apm-node").start()
```

## 总结

Node.js 性能优化需要从多个角度入手，包括事件循环、内存管理、数据库优化、缓存策略等。通过系统性的优化，可以显著提升应用性能。',
  'Node.js 应用性能优化是系统性工程，本文从事件循环、内存管理、数据库优化、缓存策略等多个维度介绍实用的优化技巧。',
  'nodejs-performance-optimization',
  'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&h=400&fit=crop',
  true,
  false,
  445,
  29,
  7,
  '550e8400-e29b-41d4-a716-446655440000'
);

-- 插入文章标签关联数据
INSERT INTO article_tags (article_id, tag_id) VALUES
-- Next.js 文章
('550e8400-e29b-41d4-a716-446655440001', (SELECT id FROM tags WHERE slug = 'nextjs')),
('550e8400-e29b-41d4-a716-446655440001', (SELECT id FROM tags WHERE slug = 'react')),
('550e8400-e29b-41d4-a716-446655440001', (SELECT id FROM tags WHERE slug = 'typescript')),
('550e8400-e29b-41d4-a716-446655440001', (SELECT id FROM tags WHERE slug = 'tutorial')),

-- React Server Components 文章
('550e8400-e29b-41d4-a716-446655440002', (SELECT id FROM tags WHERE slug = 'react')),
('550e8400-e29b-41d4-a716-446655440002', (SELECT id FROM tags WHERE slug = 'nextjs')),
('550e8400-e29b-41d4-a716-446655440002', (SELECT id FROM tags WHERE slug = 'performance')),

-- TypeScript 文章
('550e8400-e29b-41d4-a716-446655440003', (SELECT id FROM tags WHERE slug = 'typescript')),
('550e8400-e29b-41d4-a716-446655440003', (SELECT id FROM tags WHERE slug = 'javascript')),

-- CSS Grid 文章
('550e8400-e29b-41d4-a716-446655440004', (SELECT id FROM tags WHERE slug = 'css')),
('550e8400-e29b-41d4-a716-446655440004', (SELECT id FROM tags WHERE slug = 'tutorial')),

-- Node.js 文章
('550e8400-e29b-41d4-a716-446655440005', (SELECT id FROM tags WHERE slug = 'nodejs')),
('550e8400-e29b-41d4-a716-446655440005', (SELECT id FROM tags WHERE slug = 'performance')),
('550e8400-e29b-41d4-a716-446655440005', (SELECT id FROM tags WHERE slug = 'database'));

-- 插入评论数据
INSERT INTO comments (content, author_name, author_email, article_id, approved) VALUES
('非常详细的教程，对 App Router 的解释很清楚！', '李四', 'lisi@example.com', '550e8400-e29b-41d4-a716-446655440001', true),
('感谢分享，正好在学习 Next.js 14', '王五', 'wangwu@example.com', '550e8400-e29b-41d4-a716-446655440001', true),
('Server Components 确实是个革命性的特性', '赵六', 'zhaoliu@example.com', '550e8400-e29b-41d4-a716-446655440002', true),
('TypeScript 的类型系统真的很强大', '钱七', 'qianqi@example.com', '550e8400-e29b-41d4-a716-446655440003', true),
('CSS Grid 让布局变得简单多了', '孙八', 'sunba@example.com', '550e8400-e29b-41d4-a716-446655440004', true);