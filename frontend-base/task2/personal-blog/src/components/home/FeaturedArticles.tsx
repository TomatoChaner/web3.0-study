import Link from 'next/link'
import { Calendar, Clock, ArrowRight } from 'lucide-react'
import { formatDate, formatReadingTime } from '@/lib/utils'

// 模拟数据，实际项目中会从 API 获取
const featuredArticles = [
  {
    id: '1',
    title: 'Next.js 14 新特性深度解析',
    excerpt: '探索 Next.js 14 带来的革命性变化，包括 App Router、Server Components 和新的缓存策略。',
    content: '',
    slug: 'nextjs-14-deep-dive',
    created_at: '2024-01-15T10:00:00Z',
    reading_time: 8,
    featured: true,
    tags: [
      { id: '1', name: 'Next.js', slug: 'nextjs', color: '#000000' },
      { id: '2', name: 'React', slug: 'react', color: '#61DAFB' },
    ],
    author: {
      id: '1',
      name: '张三',
      email: 'zhangsan@example.com',
      avatar: '/avatars/zhangsan.jpg',
      bio: '全栈开发工程师',
    },
  },
  {
    id: '2',
    title: 'TypeScript 高级类型系统实战',
    excerpt: '深入理解 TypeScript 的高级类型特性，包括条件类型、映射类型和模板字面量类型。',
    content: '',
    slug: 'typescript-advanced-types',
    created_at: '2024-01-10T14:30:00Z',
    reading_time: 12,
    featured: true,
    tags: [
      { id: '3', name: 'TypeScript', slug: 'typescript', color: '#3178C6' },
      { id: '4', name: '前端开发', slug: 'frontend', color: '#FF6B6B' },
    ],
    author: {
      id: '1',
      name: '张三',
      email: 'zhangsan@example.com',
      avatar: '/avatars/zhangsan.jpg',
      bio: '全栈开发工程师',
    },
  },
  {
    id: '3',
    title: 'Supabase 全栈开发指南',
    excerpt: '使用 Supabase 构建现代化全栈应用，包括认证、数据库、实时功能和文件存储。',
    content: '',
    slug: 'supabase-fullstack-guide',
    created_at: '2024-01-05T09:15:00Z',
    reading_time: 15,
    featured: true,
    tags: [
      { id: '5', name: 'Supabase', slug: 'supabase', color: '#3ECF8E' },
      { id: '6', name: '全栈开发', slug: 'fullstack', color: '#8B5CF6' },
    ],
    author: {
      id: '1',
      name: '张三',
      email: 'zhangsan@example.com',
      avatar: '/avatars/zhangsan.jpg',
      bio: '全栈开发工程师',
    },
  },
]

export function FeaturedArticles() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
      {featuredArticles.map((article) => (
        <article
          key={article.id}
          className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-lg transition-shadow duration-300 group"
        >
          <div className="p-6">
            {/* Tags */}
            <div className="flex flex-wrap gap-2 mb-4">
              {article.tags.slice(0, 2).map((tag) => (
                <Link
                  key={tag.id}
                  href={`/tags/${tag.slug}`}
                  className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 hover:bg-gray-200 transition-colors duration-200"
                  style={{ backgroundColor: `${tag.color}20`, color: tag.color }}
                >
                  {tag.name}
                </Link>
              ))}
            </div>

            {/* Title */}
            <h3 className="text-xl font-bold text-gray-900 mb-3 group-hover:text-primary-600 transition-colors duration-200">
              <Link href={`/articles/${article.slug}`}>
                {article.title}
              </Link>
            </h3>

            {/* Excerpt */}
            <p className="text-gray-600 mb-4 line-clamp-3">
              {article.excerpt}
            </p>

            {/* Meta */}
            <div className="flex items-center justify-between text-sm text-gray-500">
              <div className="flex items-center space-x-4">
                <div className="flex items-center space-x-1">
                  <Calendar className="h-4 w-4" />
                  <span>{formatDate(article.created_at)}</span>
                </div>
                <div className="flex items-center space-x-1">
                  <Clock className="h-4 w-4" />
                  <span>{formatReadingTime(article.reading_time)}</span>
                </div>
              </div>
              <Link
                href={`/articles/${article.slug}`}
                className="flex items-center space-x-1 text-primary-600 hover:text-primary-700 font-medium group"
              >
                <span>阅读更多</span>
                <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform duration-200" />
              </Link>
            </div>
          </div>
        </article>
      ))}
    </div>
  )
}