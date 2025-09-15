# React TodoList 应用

一个简单的 React TodoList 应用，让用户能够添加、删除待办事项，用于熟悉 React 的基础概念，如组件、状态管理、事件处理等。

参考页面：http://todo.mewkes.cn/index.html

## 项目结构

```
react-todolist/
├── public/                    # 静态资源目录
│   ├── index.html            # HTML 模板文件
│   ├── manifest.json         # PWA 配置文件
│   └── robots.txt            # 搜索引擎爬虫配置
├── src/                      # 源代码目录
│   ├── components/           # 组件目录（待创建）
│   │   └── TodoList.jsx      # TodoList 主组件（待创建）
│   ├── App.js               # 主应用组件
│   ├── App.css              # 主应用样式
│   ├── index.js             # 应用入口文件
│   └── index.css            # 全局样式
├── package.json             # 项目依赖配置
├── package-lock.json        # 依赖版本锁定文件
├── .gitignore              # Git 忽略文件配置
├── 项目需求.md              # 项目需求文档
└── README.md               # 项目说明文档
```

## 核心功能

### 1. TodoList 组件
- **位置**: `src/components/TodoList.jsx`
- **功能**: 主要的待办事项管理组件
- **状态管理**:
  - `todos`: 存储待办事项的数组
  - `inputValue`: 存储输入框中的内容

### 2. 主要功能模块

#### 输入功能
- 输入框：用户输入新的待办事项
- 添加按钮：将输入的内容添加到待办列表
- 输入验证：确保输入内容不为空

#### 列表显示
- 待办事项列表：显示所有待办事项
- 列表项渲染：遍历 `todos` 数组进行渲染

#### 删除功能
- 删除按钮：每个列表项都有删除按钮
- 删除操作：从 `todos` 数组中移除对应项目

## 技术栈

- **React**: ^19.1.1
- **React DOM**: ^19.1.1
- **React Scripts**: 5.0.1
- **测试库**: @testing-library/react, @testing-library/jest-dom

## 开发规范

### React 最佳实践
- 使用函数式组件
- 使用 `useState` Hook 进行状态管理
- 合理的事件处理函数命名
- 组件职责单一原则

### 代码结构
- 组件文件使用 `.jsx` 扩展名
- 样式文件与组件文件分离
- 合理的文件夹结构组织

## 扩展功能（可选）

- ✅ 标记待办事项为已完成
- ✅ 待办事项编辑功能
- ✅ 本地存储持久化（localStorage）
- ✅ 待办事项分类
- ✅ 搜索和筛选功能

## 快速开始

### 安装依赖
```bash
npm install
```

### 启动开发服务器
```bash
npm start
```

### 构建生产版本
```bash
npm run build
```

### 运行测试
```bash
npm test
```

## 项目目标

通过开发这个 TodoList 应用，学习和掌握：

1. **React 基础概念**
   - 组件的创建和使用
   - JSX 语法
   - 组件间的数据传递

2. **状态管理**
   - useState Hook 的使用
   - 状态的更新和管理
   - 状态驱动的 UI 更新

3. **事件处理**
   - 用户交互事件的处理
   - 表单输入的处理
   - 事件处理函数的编写

4. **列表渲染**
   - 数组数据的渲染
   - key 属性的正确使用
   - 动态列表的更新

5. **样式处理**
   - CSS 样式的应用
   - 组件样式的组织
   - 响应式设计基础

## 开发进度

- [x] 项目初始化
- [x] 清理无关文件
- [ ] 创建 TodoList 组件
- [ ] 实现添加功能
- [ ] 实现删除功能
- [ ] 实现列表渲染
- [ ] 样式优化
- [ ] 功能测试

---

*本项目用于 React 学习和实践，适合初学者了解 React 开发流程和基础概念。*