// 文章类型
export interface Article {
  id: string
  title: string
  slug: string
  excerpt: string
  content: string
  cover_image?: string
  published: boolean
  featured: boolean
  views?: number
  view_count: number
  reading_time: number
  created_at: string
  updated_at: string
  author_id: string
  author?: Author
  tags: Tag[]
  comments?: Comment[]
}

// 标签类型
export interface Tag {
  id: string
  name: string
  slug: string
  description?: string
  color: string
  article_count: number
  created_at: string
}

// 评论类型
export interface Comment {
  id: string
  content: string
  author_name: string
  author_email: string
  author_website?: string
  article_id: string
  parent_id?: string
  approved: boolean
  like_count?: number
  created_at: string
  replies?: Comment[]
}

// 作者类型
export interface Author {
  id: string
  name: string
  email: string
  bio?: string
  avatar?: string
  website?: string
  social_links?: SocialLinks
  created_at: string
}

// 社交链接类型
export interface SocialLinks {
  github?: string
  twitter?: string
  linkedin?: string
  instagram?: string
  youtube?: string
}

// 网站统计类型
export interface SiteStats {
  total_articles: number
  total_tags: number
  total_views: number
  total_likes: number
  days_since_launch: number
}

// 分页信息
export interface Pagination {
  page: number
  limit: number
  total: number
  totalPages: number
  hasNextPage: boolean
  hasPrevPage: boolean
}

// 分页参数（别名）
export type PaginationParams = Pagination

// API 响应类型
export interface ApiResponse<T> {
  data: T
  message?: string
  success: boolean
  pagination?: Pagination
}

// 搜索参数类型
export interface SearchParams {
  q?: string
  tag?: string
  page?: number
  limit?: number
  sort?: 'latest' | 'popular' | 'oldest'
}

// 表单类型
export interface ContactForm {
  name: string
  email: string
  subject: string
  message: string
}

export interface CommentForm {
  author_name: string
  author_email: string
  author_website?: string
  content: string
  parent_id?: string
}

export interface NewsletterForm {
  email: string
}

// 导航菜单类型
export interface NavItem {
  label: string
  href: string
  icon?: string
  children?: NavItem[]
}

// SEO 元数据类型
export interface SEOData {
  title: string
  description: string
  keywords?: string[]
  image?: string
  url?: string
  type?: 'website' | 'article'
  publishedTime?: string
  modifiedTime?: string
  author?: string
}